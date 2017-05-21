
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
-- 
-- 0	eyes_updown
-- 1	eyes_rightleft
-- 2	JawOpen
-- 3	JawClose
-- 4	Smirk
-- 5	Frown
-- 6	Stretch
-- 7	Pucker
-- 8	Grin
-- 9	CatFace
-- 10	Mouth_O
-- 11	Mouth_O2
-- 12	Mouth_Full
-- 13	Tongue_Out
-- 14	Tongue_Up
-- 15	Tongue_Down
-- 16	NoEyelashes
-- 17	Eyes_Blink
-- 18	Left_Blink
-- 19	Right_Blink
-- 20	Scrunch
-- 21	FatButt
-- 22	Stomach_Out
-- 23	Stomach_In
-- 24	Throat_Bulge
-- 

net.Receive 'PPM2.DamageAnimation', ->
    ent = net.ReadEntity()
    return if not IsValid(ent) or not ent\IsPlayer()
    hook.Call('PPM2_HurtAnimation', nil, ent)

net.Receive 'PPM2.KillAnimation', ->
    ent = net.ReadEntity()
    return if not IsValid(ent) or not ent\IsPlayer()
    hook.Call('PPM2_KillAnimation', nil, ent)

DISABLE_FLEXES = CreateConVar('ppm2_disable_flexes', '0', {FCVAR_ARCHIVE}, 'Disable pony flexes controllers. Saves some FPS.')

class FlexState
    new: (controller, flexName = '', flexID = 0, scale = 1, speed = 1, active = true, min = 0, max = 1, useModifiers = true) =>
        @controller = controller
        @ent = controller.ent
        @name = flexName
        @flexName = flexName
        @flexID = flexID
        @id = flexID
        @scale = scale
        @speed = speed
        @originalscale = scale
        @originalspeed = speed
        @min = min
        @max = max
        @current = -1
        @target = 0
        @speedModify = 1
        @scaleModify = 1
        @speedModifiers = {}
        @scaleModifiers = {}
        @modifiers = {}
        @modifiersNames = {}
        @useModifiers = useModifiers
        @nextModifierID = 0
        @active = active
        @activeID = "DisableFlex#{@flexName}"
    
    GetFlexID: => @flexID
    GetFlexName: => @flexName
    
    GetModifierID: (name = '') =>
        return @modifiersNames[name] if @modifiersNames[name]
        @nextModifierID += 1
        id = @nextModifierID
        @modifiersNames[name] = id
        @speedModifiers[id] = 0
        @scaleModifiers[id] = 0
        @modifiers[id] = 0
        return id
    SetModifierWeight: (modifID, val = 0) =>
        return if not modifID
        return if not @modifiers[modifID]
        @modifiers[modifID] = val
    SetModifierScale: (modifID, val = 0) =>
        return if not modifID
        return if not @scaleModifiers[modifID]
        @scaleModifiers[modifID] = val
    SetModifierScale: (modifID, val = 0) =>
        return if not modifID
        return if not @speedModifiers[modifID]
        @speedModifiers[modifID] = val
    ResetModifiers: (name = '') =>
        return false if not @modifiersNames[name]
        id = @modifiersNames[name]
        @speedModifiers[id] = 0
        @scaleModifiers[id] = 0
        @modifiers[id] = 0
        return true
    GetEntity: => @ent
    GetData: => @controller
    GetController: => @controller
    GetValue: => @current
    GetRealValue: => @target
    SetValue: (val = @target) =>
        @current = math.Clamp(val, @min, @max) * @scale * @scaleModify
        @target = @target
    SetRealValue: (val = @target) => @target = math.Clamp(val, @min, @max) * @scale * @scaleModify

    GetScale: => @scale
    GetSpeed: => @speed
    GetScaleModify: => @scaleModify
    GetSpeedModify: => @speedModify
    GetOriginalScale: => @originalscale
    GetOriginalSpeed: => @originalspeed

    SetScale: (val = @scale) => @scale = val
    GetSpeed: (val = @speed) => @speed = val
    SetScaleModify: (val = @scaleModify) => @scaleModify = val
    GetSpeedModify: (val = @speedModify) => @speedModify = val

    GetIsActive: => @active
    SetIsActive: (val = true) => @active = val

    AddValue: (val = 0) => @SetValue(@current + val)
    AddRealValue: (val = 0) => @SetRealValue(@target + val)
    Think: (delta = 0) =>
        return if not @active
        if @useModifiers
            @target = 0
            @scale = @originalscale * @scaleModify
            @speed = @originalspeed * @speedModify
            @target += modif for modif in *@modifiers
            @scale += modif for modif in *@scaleModifiers
            @speed += modif for modif in *@speedModifiers
            @target = math.Clamp(@target, @min, @max) * @scale
        @ent = @controller.ent
        @current = Lerp(delta * 10 * @speed * @speedModify, @current, @target) if @current ~= @target
        @ent\SetFlexWeight(@flexID, @current)
    DataChanges: (state) =>
        return if state\GetKey() ~= @activeID
        @SetIsActive(not state\GetValue())
        @GetController()\RebuildIterableList()
        @Reset()
    Reset: (resetVars = true) =>
        for name, id in pairs @modifiersNames
            @speedModifiers[id] = 0
            @scaleModifiers[id] = 0
            @modifiers[id] = 0
        if resetVars
            @scaleModify = 1
            @speedModify = 1
        @scale = @originalscale * @scaleModify
        @speed = @originalspeed * @speedModify
        @target = 0
        @current = 0
        @ent\SetFlexWeight(@flexID, 0)

PPM2.FlexState = FlexState

class FlexSequence
    new: (controller, data) =>
        {
            'name': @name
            'repeat': @dorepeat
            'frames': @frames
            'time': @time
            'func': @func
            'create': @createfunc
            'ids': @flexIDsIterable
            'numid': @numid
        } = data

        @flexIDS = {}
        @flexStates = {}
        i = 1
        for id in *data.ids
            state = controller\GetFlexState(id)
            num = state\GetModifierID(@name)
            @["flex_#{id}"] = num
            @flexIDS[id] = num
            @flexStates[id] = state
            @flexStates[i] = state
            @flexIDS[i] = num
            i += 1

        @ent = controller.ent
        @controller = controller
        @frame = 0
        @start = RealTime()
        @finish = @start + @time
        @deltaAnim = 1
        @speed = 1
        @scale = 1
        @valid = true
        @createfunc() if @createfunc
    
    Reset: =>
        @frame = 0
        @start = RealTime()
        @finish = @start + @time
        @deltaAnim = 1
    
    GetController: => @controller
    GetEntity: => @ent
    GetName: => @name
    GetRepeat: => @dorepeat
    GetFrames: => @frames
    GetFrame: => @frames
    GetTime: => @time
    GetThinkFunc: => @func
    GetCreatFunc: => @createfunc
    GetSpeed: => @speed
    GetAnimationSpeed: => @speed
    GetScale: => @scale
    GetModifierID: (id = '') => @flexIDS[id]
    GetFlexState: (id = '') => @flexStates[id]

    SetModifierWeight: (id = '', val = 0) => @GetFlexState(id)\SetModifierWeight(@GetModifierID(id), val)

    IsValid: => @valid
    Think: (delta = 0) =>
        @ent = @controller.ent
        return false if not IsValid(@ent)
        return false if not @func
        if @HasFinished()
            @Stop()
            return false
        
        @deltaAnim = (@finish - RealTime()) / @time
        if @deltaAnim < 0
            @deltaAnim = 1
            @frame = 0
            @start = RealTime()
            @finish = @start + @time
        @frame += 1

        status = @func(delta, 1 - @deltaAnim)
        if status == false
            @Stop()
            return false
        
        return true
    Stop: =>
        for id in *@flexIDsIterable
            @GetController()\GetFlexState(id)\ResetModifiers(@name)
        @valid = false
    Remove: => @Stop()
    HasFinished: =>
        return false if @dorepeat
        return RealTime() > @finish

PPM2.FlexSequence = FlexSequence

class PonyFlexController
    @AVALIABLE_CONTROLLERS = {}
    @MODELS = {'models/ppm/player_default_base_new.mdl'}

    @FLEX_LIST = {
        {flex: 'eyes_updown',       scale: 1, speed: 1, active: false}
        {flex: 'eyes_rightleft',    scale: 1, speed: 1, active: false}
        {flex: 'JawOpen',           scale: 1, speed: 1, active: true}
        {flex: 'JawClose',          scale: 1, speed: 1, active: true}
        {flex: 'Smirk',             scale: 1, speed: 1, active: true}
        {flex: 'Frown',             scale: 1, speed: 1, active: true}
        {flex: 'Stretch',           scale: 1, speed: 1, active: false}
        {flex: 'Pucker',            scale: 1, speed: 1, active: false}
        {flex: 'Grin',              scale: 1, speed: 1, active: true}
        {flex: 'CatFace',           scale: 1, speed: 1, active: true}
        {flex: 'Mouth_O',           scale: 1, speed: 1, active: true}
        {flex: 'Mouth_O2',          scale: 1, speed: 1, active: true}
        {flex: 'Mouth_Full',        scale: 1, speed: 1, active: false}
        {flex: 'Tongue_Out',        scale: 1, speed: 1, active: true}
        {flex: 'Tongue_Up',         scale: 1, speed: 1, active: true}
        {flex: 'Tongue_Down',       scale: 1, speed: 1, active: true}
        {flex: 'NoEyelashes',       scale: 1, speed: 1, active: false}
        {flex: 'Eyes_Blink',        scale: 1, speed: 1, active: false}
        {flex: 'Left_Blink',        scale: 1, speed: 1, active: true}
        {flex: 'Right_Blink',       scale: 1, speed: 1, active: true}
        {flex: 'Scrunch',           scale: 1, speed: 1, active: true}
        {flex: 'FatButt',           scale: 1, speed: 1, active: false}
        {flex: 'Stomach_Out',       scale: 1, speed: 1, active: true}
        {flex: 'Stomach_In',        scale: 1, speed: 1, active: true}
        {flex: 'Throat_Bulge',      scale: 1, speed: 1, active: false}
    }

    @FLEX_SEQUENCES = {
        {
            'name': 'eyes_idle'
            'autostart': true
            'repeat': true
            'time': 5
            'ids': {'Left_Blink', 'Right_Blink'}
            'func': (delta, timeOfAnim) =>
                left, right = @GetModifierID(1), @GetModifierID(2)
                leftState, rightState = @GetFlexState(1), @GetFlexState(2)
                value = math.abs(math.sin(RealTime() * .5) * .15)
                leftState\SetModifierWeight(left, value)
                rightState\SetModifierWeight(right, value)
        }

        {
            'name': 'body_idle'
            'autostart': true
            'repeat': true
            'time': 2
            'ids': {'Stomach_Out', 'Stomach_In'}
            'func': (delta, timeOfAnim) =>
                In, Out = @GetModifierID(1), @GetModifierID(2)
                InState, OutState = @GetFlexState(1), @GetFlexState(2)
                abs = math.abs(0.5 - timeOfAnim)
                InState\SetModifierWeight(In, abs)
                OutState\SetModifierWeight(Out, abs)
        }

        {
            'name': 'health_idle'
            'autostart': true
            'repeat': true
            'time': 5
            'ids': {'Frown', 'Left_Blink', 'Right_Blink', 'Scrunch', 'Mouth_O', 'JawOpen', 'Grin'}
            'func': (delta, timeOfAnim) =>
                frown = @GetModifierID(1)
                frownState = @GetFlexState(1)
                left, right = @GetModifierID(2), @GetModifierID(3)
                leftState, rightState = @GetFlexState(2), @GetFlexState(3)
                Mouth_O, Mouth_OState = @GetModifierID(4), @GetFlexState(4)
                Scrunch = @GetModifierID(4)
                ScrunchState = @GetFlexState(4)

                hp, mhp = @ent\Health(), @ent\GetMaxHealth()
                mhp = 1 if mhp == 0
                div = hp / mhp
                strength = math.Clamp(1.5 - div * 1.5, 0, 1)
                frownState\SetModifierWeight(frown, strength)
                ScrunchState\SetModifierWeight(Scrunch, strength * .5)
                leftState\SetModifierWeight(left, strength * .1)
                rightState\SetModifierWeight(right, strength * .1)
                Mouth_OState\SetModifierWeight(Mouth_O, strength * .8)

                JawOpen = @GetModifierID(6)
                JawOpenState = @GetFlexState(6)

                if strength > .75
                    JawOpenState\SetModifierWeight(JawOpen, strength * .2 + math.sin(RealTime() * strength * 3) * .1)
                else
                    JawOpenState\SetModifierWeight(JawOpen, 0)

                if div >= 2
                    @SetModifierWeight(7, .5)
                else
                    @SetModifierWeight(7, 0)
        }

        {
            'name': 'greeny'
            'autostart': false
            'repeat': false
            'time': 2
            'ids': {'Grin'}
            'func': (delta, timeOfAnim) =>
                Grin = @GetModifierID(1)
                GrinState = @GetFlexState(1)
                strength = .5 + math.sin(RealTime() * 2) * .25
                GrinState\SetModifierWeight(Grin, strength)
        }

        {
            'name': 'big_grin'
            'autostart': false
            'repeat': false
            'time': 3
            'ids': {'Grin'}
            'func': (delta, timeOfAnim) =>
                Grin = @GetModifierID(1)
                GrinState = @GetFlexState(1)
                GrinState\SetModifierWeight(Grin, 1)
        }

        {
            'name': 'xd'
            'autostart': false
            'repeat': false
            'time': 3
            'ids': {'Grin', 'Left_Blink', 'Right_Blink', 'JawOpen'}
            'func': (delta, timeOfAnim) =>
                Grin = @GetModifierID(1)
                GrinState = @GetFlexState(1)
                GrinState\SetModifierWeight(Grin, .6)
                
                Left_Blink = @GetModifierID(2)
                Left_BlinkState = @GetFlexState(2)
                Left_BlinkState\SetModifierWeight(Left_Blink, .9)
                
                Right_Blink = @GetModifierID(3)
                Right_BlinkState = @GetFlexState(3)
                Right_BlinkState\SetModifierWeight(Right_Blink, .9)
                
                JawOpen = @GetModifierID(4)
                JawOpenState = @GetFlexState(4)
                JawOpenState\SetModifierScale(JawOpen, 2)
                JawOpenState\SetModifierWeight(JawOpen, (timeOfAnim % .1) * 2)
        }

        {
            'name': 'tongue'
            'autostart': false
            'repeat': false
            'time': 3
            'ids': {'JawOpen', 'Tongue_Out'}
            'func': (delta, timeOfAnim) =>
                @SetModifierWeight(1, .1)
                @SetModifierWeight(2, 1)
        }

        {
            'name': 'sad'
            'autostart': false
            'repeat': false
            'time': 4
            'ids': {'Frown'}
            'func': (delta, timeOfAnim) =>
                @SetModifierWeight(1, 1)
        }

        {
            'name': 'cat'
            'autostart': false
            'repeat': false
            'time': 2
            'ids': {'CatFace'}
            'func': (delta, timeOfAnim) =>
                Grin = @GetModifierID(1)
                GrinState = @GetFlexState(1)
                GrinState\SetModifierWeight(Grin, 1)
        }

        {
            'name': 'ooo'
            'autostart': false
            'repeat': false
            'time': 2
            'ids': {'Mouth_O2', 'Mouth_O'}
            'func': (delta, timeOfAnim) =>
                timeOfAnim *= 2
                Grin = @GetModifierID(1)
                GrinState = @GetFlexState(1)
                GrinState\SetModifierWeight(Grin, timeOfAnim)
                Grin = @GetModifierID(2)
                GrinState = @GetFlexState(2)
                GrinState\SetModifierWeight(Grin, timeOfAnim)
        }

        {
            'name': 'talk'
            'autostart': false
            'repeat': false
            'time': 2
            'ids': {'JawOpen', 'Tongue_Out', 'Tongue_Up', 'Tongue_Down'}
            'create': =>
                @talkAnim = for i = 0, 1, 0.05
                    rand = math.random(1, 100) / 100
                    if rand <= .25
                        {1 * rand, 0.4 * rand, 2 * rand, 0}
                    elseif rand >= .25 and rand < .4
                        rand *= .8
                        {2 * rand, .6 * rand, 0, 1 * rand}
                    elseif rand >= .4 and rand < .75
                        rand *= .6
                        {1 * rand, 0, 1 * rand, 2 * rand}
                    elseif rand >= .75
                        rand *= .4
                        {1.5 * rand, 0, 1 * rand, 0}
            'func': (delta, timeOfAnim) =>
                JawOpen = @GetModifierID(1)
                JawOpenState = @GetFlexState(1)
                Tongue_OutOpen = @GetModifierID(2)
                Tongue_OutOpenState = @GetFlexState(2)
                Tongue_UpOpen = @GetModifierID(3)
                Tongue_UpOpenState = @GetFlexState(3)
                Tongue_DownOpen = @GetModifierID(4)
                Tongue_DownOpenState = @GetFlexState(4)
                cPos = math.floor(timeOfAnim * 20) + 1
                data = @talkAnim[cPos]
                return if not data
                {jaw, out, up, down} = data
                JawOpenState\SetModifierWeight(JawOpen, jaw)
                Tongue_OutOpenState\SetModifierWeight(Tongue_OutOpen, out)
                Tongue_UpOpenState\SetModifierWeight(Tongue_UpOpen, up)
                Tongue_DownOpenState\SetModifierWeight(Tongue_DownOpen, down)
        }

        {
            'name': 'talk_endless'
            'autostart': false
            'repeat': true
            'time': 4
            'ids': {'JawOpen', 'Tongue_Out', 'Tongue_Up', 'Tongue_Down'}
            'create': =>
                @talkAnim = for i = 0, 1, 0.05
                    rand = math.random(1, 100) / 100
                    if rand <= .25
                        {1 * rand, 0.4 * rand, 2 * rand, 0}
                    elseif rand >= .25 and rand < .4
                        rand *= .8
                        {2 * rand, .6 * rand, 0, 1 * rand}
                    elseif rand >= .4 and rand < .75
                        rand *= .6
                        {1 * rand, 0, 1 * rand, 2 * rand}
                    elseif rand >= .75
                        rand *= .4
                        {1.5 * rand, 0, 1 * rand, 0}
            'func': (delta, timeOfAnim) =>
                JawOpen = @GetModifierID(1)
                JawOpenState = @GetFlexState(1)
                Tongue_OutOpen = @GetModifierID(2)
                Tongue_OutOpenState = @GetFlexState(2)
                Tongue_UpOpen = @GetModifierID(3)
                Tongue_UpOpenState = @GetFlexState(3)
                Tongue_DownOpen = @GetModifierID(4)
                Tongue_DownOpenState = @GetFlexState(4)
                cPos = math.floor(timeOfAnim * 20) + 1
                data = @talkAnim[cPos]
                return if not data
                {jaw, out, up, down} = data
                volume = @ent\VoiceVolume() * 6
                jaw *= volume
                out *= volume
                up *= volume
                down *= volume
                JawOpenState\SetModifierWeight(JawOpen, jaw)
                Tongue_OutOpenState\SetModifierWeight(Tongue_OutOpen, out)
                Tongue_UpOpenState\SetModifierWeight(Tongue_UpOpen, up)
                Tongue_DownOpenState\SetModifierWeight(Tongue_DownOpen, down)
        }

        {
            'name': 'eyes_blink'
            'autostart': true
            'repeat': true
            'time': 7
            'ids': {'Left_Blink', 'Right_Blink'}
            'create': =>
                @nextBlink = math.random(300, 600) / 1000
                @nextBlinkLength = math.random(50, 75) / 1000
                @min, @max = @nextBlink, @nextBlink + @nextBlinkLength
            'func': (delta, timeOfAnim) =>
                if @min > timeOfAnim or @max < timeOfAnim
                    if @blinkHit
                        @blinkHit = false
                        left, right = @GetModifierID(1), @GetModifierID(2)
                        leftState, rightState = @GetFlexState(1), @GetFlexState(2)
                        leftState\SetModifierWeight(left, 0)
                        rightState\SetModifierWeight(right, 0)
                    return
                left, right = @GetModifierID(1), @GetModifierID(2)
                leftState, rightState = @GetFlexState(1), @GetFlexState(2)
                leftState\SetModifierWeight(left, .9)
                rightState\SetModifierWeight(right, .9)
                @blinkHit = true
        }

        {
            'name': 'hurt'
            'autostart': false
            'repeat': false
            'time': 2
            'ids': {'JawOpen', 'Frown', 'Grin', 'Scrunch'}
            'func': (delta, timeOfAnim) =>
                @SetModifierWeight(1, .08)
                @SetModifierWeight(2, .69)
                @SetModifierWeight(3, .36)
                @SetModifierWeight(4, .81)
        }

        {
            'name': 'kill_grin'
            'autostart': false
            'repeat': false
            'time': 3
            'ids': {'Smirk', 'Frown', 'Grin'}
            'func': (delta, timeOfAnim) =>
                @SetModifierWeight(1, .51)
                @SetModifierWeight(2, .38)
                @SetModifierWeight(3, .66)
        }
    }

    @__inherited: (child) =>
        child.MODELS_HASH = {mod, true for mod in *child.MODELS}
        @AVALIABLE_CONTROLLERS[mod] = child for mod in *child.MODELS
        for i, flex in pairs child.FLEX_LIST
            flex.id = i - 1
            flex.targetName = "target#{flex.flex}"
        child.FLEX_IDS = {flex.id, flex for flex in *child.FLEX_LIST}
        child.FLEX_TABLE = {flex.flex, flex for flex in *child.FLEX_LIST}
        seq.numid = i for i, seq in pairs child.FLEX_SEQUENCES
        child.FLEX_SEQUENCES_TABLE = {seq.name, seq for seq in *child.FLEX_SEQUENCES}
        child.FLEX_SEQUENCES_TABLE[seq.numid] = seq for seq in *child.FLEX_SEQUENCES
    @__inherited(@)

    @NEXT_HOOK_ID = 0

    new: (data) =>
        @controller = data
        @ent = data.ent
        @states = [FlexState(@, flex, id, scale, speed, active) for {:flex, :id, :scale, :speed, :active} in *@@FLEX_LIST]
        @statesTable = {state\GetFlexName(), state for state in *@states}
        @statesTable[state\GetFlexName()\lower()] = state for state in *@states
        @statesTable[state\GetFlexID()] = state for state in *@states
        @RebuildIterableList()
        @hooks = {}
        @@NEXT_HOOK_ID += 1
        @fid = @@NEXT_HOOK_ID
        @hookID = "PPM2.FlexController.#{@@NEXT_HOOK_ID}"
        @lastThink = RealTime()
        @currentSequences = {}
        @currentSequencesIterable = {}
        @ResetSequences()
        @Hook('OnPlayerChat', @OnPlayerChat)
        @Hook('PlayerStartVoice', @PlayerStartVoice)
        @Hook('PlayerEndVoice', @PlayerEndVoice)
        @Hook('PPM2_HurtAnimation', @PPM2_HurtAnimation)
        @Hook('PPM2_KillAnimation', @PPM2_KillAnimation)
    
    StartSequence: (seqID = '') =>
        return @currentSequences[seqID] if @currentSequences[seqID]
        return if not @@FLEX_SEQUENCES_TABLE[seqID]
        @currentSequences[seqID] = FlexSequence(@, @@FLEX_SEQUENCES_TABLE[seqID])
        @currentSequencesIterable = [seq for i, seq in pairs @currentSequences]
        return @currentSequences[seqID]

    RestartSequence: (seqID = '') =>
        if @currentSequences[seqID]
            @currentSequences[seqID]\Reset()
            return @currentSequences[seqID]
        return @StartSequence(seqID)
    
    EndSequence: (seqID = '', callStop = true) =>
        return false if not @currentSequences[seqID]
        @currentSequences[seqID]\Stop() if callStop
        @currentSequences[seqID] = nil
        @currentSequencesIterable = [seq for i, seq in pairs @currentSequences]
        return true
    
    ResetSequences: =>
        for seq in *@currentSequencesIterable
            seq\Stop()
        
        @currentSequences = {}
        @currentSequencesIterable = {}
        state\Reset(false) for state in *@statesIterable

        for seq in *@@FLEX_SEQUENCES
            continue if not seq.autostart
            @StartSequence(seq.name)
    
    PlayerRespawn: =>
        @ResetSequences()

    HasSequence: (seqID = '') => @currentSequences[seqID] and true or false
    
    GetFlexState: (name = '') => @statesTable[name]
    RebuildIterableList: =>
        @statesIterable = for state in *@states
            continue if not state\GetIsActive()
            state
    DataChanges: (state) =>
        flexState\DataChanges(state) for flexState in *@states
    GetEntity: => @ent
    GetData: => @controller
    GetController: => @controller

    Hook: (id, func) =>
        newFunc = (...) ->
            if not IsValid(@ent)
                @ent = @GetData().ent
            if not IsValid(@ent) or @GetData()\GetData() ~= @ent\GetPonyData()
                @RemoveHooks()
                return
            func(@, ...)
            return nil
        hook.Add id, @hookID, newFunc
        table.insert(@hooks, id)
    
    OnPlayerChat: (ply = NULL, text = '', teamOnly = false, isDead = false) =>
        return if ply ~= @ent or teamOnly or isDead
        switch text\lower()
            when 'o'
                @RestartSequence('ooo')
            when ':o'
                @RestartSequence('ooo')
            when 'о'
                @RestartSequence('ooo')
            when 'О'
                @RestartSequence('ooo')
            when ':о'
                @RestartSequence('ooo')
            when ':О'
                @RestartSequence('ooo')
            when ':3'
                @RestartSequence('cat')
            when ':з'
                @RestartSequence('cat')
            when ':d'
                @RestartSequence('big_grin')
            when 'xd'
                @RestartSequence('xd')
            when 'exdi'
                @RestartSequence('xd')
            when ':p'
                @RestartSequence('tongue')
            when ':р'
                @RestartSequence('tongue')
            when ':Р'
                @RestartSequence('tongue')
            when ':c'
                @RestartSequence('sad')
            when ':('
                @RestartSequence('sad')
            when '('
                @RestartSequence('sad')
            when ':с'
                @RestartSequence('sad')
            when ':С'
                @RestartSequence('sad')
            else
                if string.find(text, 'hehehe') or string.find(text, 'hahaha')
                    @RestartSequence('greeny')
                else
                    @RestartSequence('talk')
    PlayerStartVoice: (ply = NULL) =>
        return if ply ~= @ent
        @StartSequence('talk_endless')
    PlayerEndVoice: (ply = NULL) =>
        return if ply ~= @ent
        @EndSequence('talk_endless')
    PPM2_HurtAnimation: (ply = NULL) =>
        return if ply ~= @ent
        @RestartSequence('hurt')
    PPM2_KillAnimation: (ply = NULL) =>
        return if ply ~= @ent
        @RestartSequence('kill_grin')

    RemoveHooks: =>
        for iHook in *@hooks
            hook.Remove iHook, @hookID

    Think: =>
        return if DISABLE_FLEXES\GetBool()
        if not IsValid(@ent)
            @ent = @GetData().ent
        return if not IsValid(@ent) or @ent\IsDormant() or not @ent\Alive()
        delta = RealTime() - @lastThink
        @lastThink = RealTime()
        state\Think(delta) for state in *@statesIterable
        for seq in *@currentSequencesIterable
            if not seq\IsValid()
                @EndSequence(seq\GetName(), false)
                break
            seq\Think(delta)

do
    ppm2_disable_flexes = (cvar, oldval, newval) ->
        for ply in *player.GetAll()
            data = ply\GetPonyData()
            continue if not data
            flex = data\GetFlexController()
            continue if not flex
            flex\ResetSequences()
    cvars.AddChangeCallback 'ppm2_disable_flexes', ppm2_disable_flexes, 'ppm2_disable_flexes'

PPM2.PonyFlexController = PonyFlexController
PPM2.GetFlexController = (model = 'models/ppm/player_default_base_new.mdl') -> PonyFlexController.AVALIABLE_CONTROLLERS[model]