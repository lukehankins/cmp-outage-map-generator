import argparse
from pathlib import Path
import random
import sys
from time import sleep
from urllib import request
import zipfile

from bs4 import BeautifulSoup
import matplotlib.pyplot as plt
import shapefile
from tqdm import tqdm


# Parse arguments
parser = argparse.ArgumentParser()
noise_group = parser.add_mutually_exclusive_group()
noise_group.add_argument('-v', '--verbose', help='Verbose', default=0, action='count')
noise_group.add_argument('-q', '--quiet', help='Quiet', action='store_true')
parser.add_argument('-d', '--demo', help='Demo mode', action='store_true')
parser.add_argument('-o', '--output', help='Output file (defaults to "cmp-outages.png")', default='cmp-outages.png', action='store')
parser.add_argument('-w', '--width', help='Width in "inches", depending on dpi (defaults to 12.0)',
                    default=12.0, type=float, action='store')
bbox_group = parser.add_mutually_exclusive_group()
bbox_group.add_argument('-e', '--entirestate', help='Show entire state', action='store_true')
bbox_group.add_argument('-z', '--zoom', help='Zoom to only this town (mupltiple allowed)',
                        metavar='TOWN', default=[], action='append')
parser.add_argument('-i', '--interesting', help='Highlight this town (mupltiple allowed)',
                    metavar='TOWN', default=[], action='append')
parser.add_argument('-f', '--fast', help='Skip drawing smaller non-interesting roads', action='store_true')
args = parser.parse_args()

# Set some variables
base_url = 'http://www3.cmpco.com/OutageReports/'
top_url = base_url + '/CMP.html'
affected = []
[xmin, ymin, xmax, ymax] = [0, 1, 2, 3]


# If we're in demo mode, don't bother downloading the page and pick roads at random later on
if args.demo:
    if args.verbose:
        print('Demo mode enabled')
    top_table_rows = []
else:
    top_table_rows = BeautifulSoup(request.urlopen(top_url), 'html.parser').findChildren('tr')

# Parse the top page and children, recursively
for top_table_row in top_table_rows:
    if 'No reported electricity outages are in our system.' in top_table_row.text:
        if not args.quiet:
            print('WARNING: no outages.  Use --demo for a demo dataset')
        break
    county_a = top_table_row.find('a')
    if not county_a:
        continue
    county_name = county_a.text
    sleep(1)
    county_table_rows = BeautifulSoup(request.urlopen(base_url + county_a['href']), 'html.parser').findChildren('tr')
    for county_table_row in county_table_rows:
        town_a = county_table_row.find('a')
        if not town_a or town_a['href'] == 'CMP.html':
            continue
        town_name = town_a.text
        sleep(1)
        town_table_rows = BeautifulSoup(request.urlopen(base_url + town_a['href']), 'html.parser').findChildren('tr')
        for town_table_row in town_table_rows[3:-1]:
            road_name = town_table_row.find('td').text
            affected.append([county_name, town_name, road_name])
            if args.verbose:
                print('Outage found on {}, {}, {}'.format(county_name, town_name, road_name))

# Create some lookup tables
affected_counties = list(set([x[0] for x in affected]))
affected_towns = list(set([x[1] for x in affected]))
interesting_towns = list(set([x.upper() for x in args.interesting]))
zoom_towns = list(set([x.upper() for x in args.zoom]))

# Make sure the shapefiles are unpacked and load them
if not Path('Maine_E911_NG_Roads/Maine_E911_NG_Roads.shp').exists():
    if Path('Maine_E911_NG_Roads.zip').exists():
        if not args.quiet:
            print('Unzipping shapefiles...')
        zipfile.ZipFile('Maine_E911_NG_Roads.zip','r').extractall('Maine_E911_NG_Roads')
        if not args.quiet:
            print('...done.')
    else:
        print('ERROR: no .ship file in Maine_E911_NG_Roads/Maine_E911_NG_Roads.shp and no zip to unpack')
        sys.exit()
sf = shapefile.Reader('Maine_E911_NG_Roads/Maine_E911_NG_Roads.shp')

# Set up the chart
fig = plt.figure()
ax = fig.add_subplot(111)

# Set the default bounding box to absurd reverse values if there's something to show
if affected or args.demo:
    bbox = [sf.bbox[xmax], sf.bbox[ymax], sf.bbox[xmin], sf.bbox[ymin]]
else:
    bbox = [sf.bbox[xmin], sf.bbox[ymin], sf.bbox[xmax], sf.bbox[ymax]]

# Want a pretty progress bar?
if args.quiet:
    allRoadIterator = sf.iterShapeRecords()
else:
    print('Checking roads...')
    # TODO: pull length from shapefile rather than hardcoding
    allRoadIterator = tqdm(sf.iterShapeRecords(), total=145148)

try:
    for shapeRec in allRoadIterator:

        # If we're in demo mode, take 10% at random
        demo_victim = args.demo and random.random() < 0.10

        town_name = shapeRec.record[11].upper()
        road_name = shapeRec.record[6].upper()
        county_name = shapeRec.record[16].upper()
        speed = int(shapeRec.record[35] or 0)
        road_class = shapeRec.record[36].upper()

        if args.verbose >= 3:
            print('=====')
            for i in range(0,len(sf.fields)-1):
                print('{} : {} : {}'.format(i,sf.fields[i+1][0],shapeRec.record[i]))

        if ([county_name, town_name, road_name] in affected) or demo_victim:
            # TODO: set line color based on percent of customers affected
            alpha = 1.0
            color = 'red'
        elif town_name in interesting_towns:
            alpha = 0.50
            color = 'lightgreen'
        else:
            alpha = 0.30
            color = 'black'

        # TODO: This logic to set the viewport is likely more convoluted than it needs to be
        show_road = False
        if args.zoom:
            # If args.zoom is set, we only care about those towns
            if town_name in zoom_towns:
                show_road = True
        else:
            if town_name in affected_towns:
                show_road = True
            if args.entirestate:
                show_road = True
            if town_name in interesting_towns:
                show_road = True
            if demo_victim:
                show_road = True
        if show_road:
            bbox[xmin] = min(bbox[xmin], shapeRec.shape.bbox[xmin])
            bbox[ymin] = min(bbox[ymin], shapeRec.shape.bbox[ymin])
            bbox[xmax] = max(bbox[xmax], shapeRec.shape.bbox[xmax])
            bbox[ymax] = max(bbox[ymax], shapeRec.shape.bbox[ymax])

        if not (args.fast and color is 'black' and speed < 36):
            line = plt.Polygon(shapeRec.shape.points, fill=False, closed=False, color=color, alpha=alpha)
            ax.add_patch(line)

    plt.xlim([bbox[xmin], bbox[xmax]])
    plt.ylim([bbox[ymin], bbox[ymax]])

    ratio = ((bbox[ymax] - bbox[ymin]) / (bbox[xmax] - bbox[xmin]))
    fig.set_size_inches(args.width, args.width * ratio)

    if args.verbose:
        print('Generating map...')

    # TODO: This is to keep the title from causing an exception.  Hack.
    # TODO: trim sys.argv to a length that won't cause issues
    if args.width > 5:
        plt.title(str.join(' ', sys.argv))

    plt.gca().axes.get_xaxis().set_ticks([])
    plt.gca().axes.get_yaxis().set_ticks([])

    plt.tight_layout()
    plt.savefig(args.output)

    # TODO: make show() work
    # plt.show()

    if not args.quiet:
        print('Wrote map to', args.output)

except KeyboardInterrupt:
    print('Interrupt recieved.  Exiting.')
    sys.exit()
