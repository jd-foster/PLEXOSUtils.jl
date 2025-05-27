using Test

using PLEXOSUtils
const PLU = PLEXOSUtils

using OrderedCollections: OrderedDict
using Preferences

set_preferences!("PLEXOSUtils",
    "types_def_file" =>  "types_v9_ISP.jl",
    "table_def_file" => "tabledefs_v9_ISP.jl";
    force=true
)

model_filename = "Reduced_PLEXOS_DLT_Model"
model_zipname = model_filename*".zip"
scenario = "2024 ISP Green Energy Exports"
xml_file_key = joinpath(model_filename, scenario, scenario*" Model.xml")

zipfiles = OrderedDict(
    model_zipname => xml_file_key
)

function run_tests(zipname::String, xmlfilepath::String;
    testfolder=joinpath(@__DIR__,"test_data"))
    
    zippath = joinpath(testfolder, zipname)
    zip_archive = PLU._open_plexoszip(zippath)
    xml = PLU.parsexml(zip_archive[xmlfilepath])

    # Create our dataset objects:
    summ0 = PLEXOSSolutionDatasetSummary(xml);
    ds, summ1 = open_plexoszip(zippath, xmlfilepath; consolidated=false);

    @test summ0 == summ1;     # The summary should be the same when created either directly or with the complete parser.
    @test ds == deepcopy(ds); # Equality should hold between complete copies of the dataset.

    # The summary should reflect the length of the complete dataset:
    for i in propertynames(summ1)
        (i == :index_map) && continue
        t = getfield(summ1,i) # t is a tuple (count of data points, maximum data index)
        if !isempty(t)
            @test last(t) == length(getfield(ds,i))
        end
    end

    # Consolidation tests:
    cnds0, summ2 = open_plexoszip(zippath, xmlfilepath; consolidated=true);
    cnds1 = PLU.consolidate(ds, summ1);
    @test cnds0 == cnds1; # They should be the same either directly or with the complete parser.
    @test ds !== cnds0;   # The unconsolidated dataset should not equal the consolidated one.
    @test summ1 == summ2; # The summary should not change however.

    # The consolidated dataset should now be the length of the actual defined data:
    for i in propertynames(summ2)
        (i == :index_map) && continue
        t = getfield(summ2,i) # t is a tuple (count of data points, maximum data index)
        if !isempty(t)
            @test first(t) == length(getfield(cnds0, i))
        end
    end

    # The "unit labels" table has an index offset of 0, so test this and checkref:
    LU = length(ds.unit)
    @test PLU.checkref(ds, :unit, 1) == true
    @test PLU.checkref(ds, :unit, 0) == false
    @test PLU.checkref(cnds0, :unit, 0) == true
    @test PLU.checkref(ds, :unit, LU - 1) == true
    @test PLU.checkref(ds, :unit, LU) == true
    @test PLU.checkref(cnds0, :unit, LU - 1) == true
    @test PLU.checkref(cnds0, :unit, LU) == false
end

# TODO: Actually test things
@testset "Read PLEXOS zip files" begin
    for (zip_file, xml_key) in zipfiles
        println("Testing the reading of zipfile $(zip_file)")
        run_tests(zip_file, xml_key) #; testfolder=model_folder)
    end
end