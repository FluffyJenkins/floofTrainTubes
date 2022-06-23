data:extend({
    {
        type = "int-setting",
        name = "floofTrainTubes-requestLimiter",
        localised_name = {"floofTrainTubesSetting.requestLimiter"},
        setting_type = "runtime-global",
        minimum_value = 1,
        default_value = 400,
        maximum_value = 10000
    },
    {
        type = "int-setting",
        name = "floofTrainTubes-requestRate",
        localised_name = {"floofTubeTubesSetting.requestRate"},
        setting_type = "runtime-global",
        minimum_value = 10,
        default_value = 300,
        maximum_value = 1200
    }
})