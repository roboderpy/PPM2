
--
-- Copyright (C) 2017 DBot
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

timer.Create 'PPM2.ModelWatchdog', 1, 0, ->
    for ply in *player.GetAll()
        model = ply\GetModel()
        ply.__ppm2_lastmodel = ply.__ppm2_lastmodel or model
        if ply.__ppm2_lastmodel ~= model
            data = ply\GetPonyData()
            if data and data.ModelChanges
                data\ModelChanges(ply.__ppm2_lastmodel, model)
                ply.__ppm2_lastmodel = model

do
    catchError = (err) ->
        PPM2.Message 'Slow Update Error: ', err
        PPM2.Message debug.traceback()
    timer.Create 'PPM2.SlowUpdate', 5, 0, ->
        for ply in *player.GetAll()
            continue if not ply\Alive()
            data = ply\GetPonyData()
            continue if not data
            xpcall(data.SlowUpdate, catchError, data, CLIENT) if data.SlowUpdate

DISABLE_HOOFSTEP_SOUND_CLIENT = CreateConVar('ppm2_cl_no_hoofsound', '0', {FCVAR_ARCHIVE}, 'Disable hoofstep sound play time') if CLIENT
DISABLE_HOOFSTEP_SOUND = CreateConVar('ppm2_no_hoofsound', '0', {FCVAR_ARCHIVE, FCVAR_REPLICATED}, 'Disable hoofstep sound play time')

hook.Add 'PlayerStepSoundTime', 'PPM2.Hooks', (stepType = STEPSOUNDTIME_NORMAL, isWalking = false) =>
    return if not IsValid(@)
    return if not @IsPonyCached()
    return if CLIENT and DISABLE_HOOFSTEP_SOUND_CLIENT\GetBool()
    return if DISABLE_HOOFSTEP_SOUND\GetBool()
    rate = @GetPlaybackRate() * .5
    if @Crouching()
        switch stepType
            when STEPSOUNDTIME_NORMAL
                return not isWalking and (300 / rate) or (600 / rate)
            when STEPSOUNDTIME_ON_LADDER
                return 500 / rate
            when STEPSOUNDTIME_WATER_KNEE
                return not isWalking and (400 / rate) or (800 / rate)
            when STEPSOUNDTIME_WATER_FOOT
                return not isWalking and (350 / rate) or (700 / rate)
    else
        switch stepType
            when STEPSOUNDTIME_NORMAL
                return not isWalking and (150 / rate) or (300 / rate)
            when STEPSOUNDTIME_ON_LADDER
                return 500 / rate
            when STEPSOUNDTIME_WATER_KNEE
                return not isWalking and (250 / rate) or (500 / rate)
            when STEPSOUNDTIME_WATER_FOOT
                return not isWalking and (175 / rate) or (350 / rate)
