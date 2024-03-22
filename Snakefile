acs_year = 2022
cdc_year = 2023

cities = ['bridgeport', 'hartford', 'new_haven', 'stamford']

def r_with_args(script):
    cmd = f'Rscript {script} {acs_year} {cdc_year}'
    return cmd

rule download_data:
    output:
        acs = f'input_data/acs_nhoods_by_city_{acs_year}.rds',
        cdc = f'input_data/cdc_health_all_lvls_nhood_{cdc_year}.rds',
        acs_head = '_utils/acs_indicator_headings.txt',
        cdc_head = '_utils/cdc_indicators.txt',
    params:
        acs_year = acs_year,
        cdc_year = cdc_year,
    shell:
        '''
        bash ./scripts/00a_download_data.sh {params.acs_year} {params.cdc_year} 
        '''

rule headings:
    input:
        rules.download_data.output.acs_head,
        rules.download_data.output.cdc_head,
    output:
        'to_viz/indicators.json',
    script:
        'scripts/00b_make_headings.R'

rule notes:
    input:
        '_utils/manual/sources.txt',
        '_utils/manual/urls.txt',
        rules.download_data.output.acs,
        rules.download_data.output.cdc,
    output:
        notes = 'to_viz/notes.json',
        geos = '_utils/city_geos.rds'
    script:
        'scripts/00c_make_geo_notes.R'

rule combine_datasets:
    input:
        rules.download_data.output.acs,
        rules.download_data.output.cdc,
        rules.notes.output.geos,
    params:
        acs_year = acs_year,
        cdc_year = cdc_year,
    output:
        comb = f'output_data/all_nhood_{acs_year}_acs_health_comb.rds',
    script:
        'scripts/01_join_acs_health.R'

rule distro:
    input:
        rules.headings.output,
        rules.combine_datasets.output.comb,
    params:
        acs_year = acs_year,
    output:
        expand('to_distro/{city}_nhood_{year}_acs_health_comb.csv', city = cities, year = acs_year),
    script:
        'scripts/02_prep_distro.R'

rule viz_data:
    input:
        rules.combine_datasets.output.comb,
    params:
        acs_year = acs_year,
    output:
        viz = f'to_viz/nhood_wide_{acs_year}.json',
    script:
        'scripts/03_prep_json_to_viz.R'


rule make_shapes:
    output:
        expand('to_viz/cities/{city}_topo.json', city = cities),
    script:
        'scripts/04_make_shapefiles.R'


rule upload_shapes:
    input:
        rules.make_shapes.output,
    output:
        touch('.shapes_uploaded')
    shell:
        'bash ./scripts/05_upload_shapes_release.sh {input}'


rule clean:
    shell:
        '''
        rm -f to_distro/*.csv \
            to_viz/*.json \
            to_viz/cities/*.json \
            input_data/*.rds \
            output_data/*.rds \
            _utils/*.txt \
            _utils/*.rds
        '''

rule all:
    default_target: True
    input:
        rules.viz_data.output,
        rules.distro.output,
        rules.upload_shapes.output

# doesn't work until distro files are already pushed to github
# rule distro:
#     input:
#         rules.headings.output,
#         rules.combine_datasets.output.comb,
#     params:
#         acs_year = acs_year,
#     output:
#         expand('to_distro/{city}_nhood_{year}_acs_health_comb.csv', city = cities, year = acs_year),
#     shell:
#         # need to run from shell so it doesn't run vanilla
#         'Rscript scripts/02_prep_distro.R {params.acs_year}'
