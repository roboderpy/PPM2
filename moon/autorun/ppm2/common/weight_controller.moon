
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

-- it is defined shared, but used clientside only

-- 0	LrigPelvis
-- 1	LrigSpine1
-- 2	LrigSpine2
-- 3	LrigRibcage
-- 4	LrigNeck1
-- 5	LrigNeck2
-- 6	LrigNeck3
-- 7	LrigScull
-- 8	Lrig_LEG_BL_Femur
-- 9	Lrig_LEG_BL_Tibia
-- 10	Lrig_LEG_BL_LargeCannon
-- 11	Lrig_LEG_BL_PhalanxPrima
-- 12	Lrig_LEG_BL_RearHoof
-- 13	Lrig_LEG_BR_Femur
-- 14	Lrig_LEG_BR_Tibia
-- 15	Lrig_LEG_BR_LargeCannon
-- 16	Lrig_LEG_BR_PhalanxPrima
-- 17	Lrig_LEG_BR_RearHoof
-- 18	Lrig_LEG_FL_Scapula
-- 19	Lrig_LEG_FL_Humerus
-- 20	Lrig_LEG_FL_Radius
-- 21	Lrig_LEG_FL_Metacarpus
-- 22	Lrig_LEG_FL_PhalangesManus
-- 23	Lrig_LEG_FL_FrontHoof
-- 24	Lrig_LEG_FR_Scapula
-- 25	Lrig_LEG_FR_Humerus
-- 26	Lrig_LEG_FR_Radius
-- 27	Lrig_LEG_FR_Metacarpus
-- 28	Lrig_LEG_FR_PhalangesManus
-- 29	Lrig_LEG_FR_FrontHoof
-- 30	Mane01
-- 31	Mane02
-- 32	Mane03
-- 33	Mane04
-- 34	Mane05
-- 35	Mane06
-- 36	Mane07
-- 37	Mane03_tip
-- 38	Tail01
-- 39	Tail02
-- 40	Tail03

class PonyWeightController
    @AVALIABLE_CONTROLLERS = {}
    @MODELS = {'models/ppm/player_default_base.mdl', 'models/ppm/player_default_base_nj.mdl', 'models/cppm/player_default_base.mdl', 'models/cppm/player_default_base_nj.mdl'}
    @__inherited: (child) =>
        child.MODELS_HASH = {mod, true for mod in *child.MODELS}
        @AVALIABLE_CONTROLLERS[mod] = child for mod in *child.MODELS
    @__inherited(@)

    @HARD_LIMIT_MINIMAL = 0.1
    @HARD_LIMIT_MAXIMAL = 3

    new: (data, applyWeight = true) =>
        @isValid = true
        @networkedData = data
        @ent = data.ent
        @SetWeight(data\GetWeight())
        @UpdateWeight() if IsValid(@ent) and applyWeight
    
    IsValid: => IsValid(@ent) and @isValid
    GetEntity: => @ent
    GetData: => @networkedData
    GetController: => @networkedData
    GetModel: => @networkedData\GetModel()

    @WEIGHT_BONES = {
        {id: 1, scale: 0.7}
        {id: 2, scale: 0.7}
    }

    table.insert(@WEIGHT_BONES, {id: i, scale: 1}) for i = 8, 29

    DataChanges: (state) =>
        return if not IsValid(@ent)
        return if state\GetKey() ~= 'Weight'
        return if not @isValid
        @SetWeight(state\GetValue())
        @UpdateWeight()

    SetWeight: (weight = 1) => @weight = math.Clamp(weight, @@HARD_LIMIT_MINIMAL, @@HARD_LIMIT_MAXIMAL)

    @DEFAULT_BONE_SIZE = Vector(1, 1, 1)
    ResetBones: (ent = @ent) =>
        return if not IsValid(ent)
        return if not @isValid
        for i = 0, ent\GetBoneCount() - 1
            ent\ManipulateBoneScale(i, @@DEFAULT_BONE_SIZE)
    UpdateWeight: (ent = @ent) =>
        return if not IsValid(ent)
        return if not @isValid
        @ResetBones(ent)
        for {:id, :scale} in *@@WEIGHT_BONES
            ent\ManipulateBoneScale(id, Vector(scale * @weight, scale * @weight, scale * @weight))
    Remove: =>
        @isValid = false

-- 0	LrigPelvis
-- 1	Lrig_LEG_BL_Femur
-- 2	Lrig_LEG_BL_Tibia
-- 3	Lrig_LEG_BL_LargeCannon
-- 4	Lrig_LEG_BL_PhalanxPrima
-- 5	Lrig_LEG_BL_RearHoof
-- 6	Lrig_LEG_BR_Femur
-- 7	Lrig_LEG_BR_Tibia
-- 8	Lrig_LEG_BR_LargeCannon
-- 9	Lrig_LEG_BR_PhalanxPrima
-- 10	Lrig_LEG_BR_RearHoof
-- 11	LrigSpine1
-- 12	LrigSpine2
-- 13	LrigRibcage
-- 14	Lrig_LEG_FL_Scapula
-- 15	Lrig_LEG_FL_Humerus
-- 16	Lrig_LEG_FL_Radius
-- 17	Lrig_LEG_FL_Metacarpus
-- 18	Lrig_LEG_FL_PhalangesManus
-- 19	Lrig_LEG_FL_FrontHoof
-- 20	Lrig_LEG_FR_Scapula
-- 21	Lrig_LEG_FR_Humerus
-- 22	Lrig_LEG_FR_Radius
-- 23	Lrig_LEG_FR_Metacarpus
-- 24	Lrig_LEG_FR_PhalangesManus
-- 25	Lrig_LEG_FR_FrontHoof
-- 26	LrigNeck1
-- 27	LrigNeck2
-- 28	LrigNeck3
-- 29	LrigScull
-- 30	Ear_L
-- 31	Ear_R
-- 32	__INVALIDBONE__

class NewPonyWeightController extends PonyWeightController
    @MODELS = {'models/ppm/player_default_base_new.mdl'}

    @WEIGHT_BONES = {
        {id: 11, scale: 0.7}
        {id: 12, scale: 0.7}
    }

    table.insert(@WEIGHT_BONES, {id: i, scale: 1}) for i = 1, 10
    table.insert(@WEIGHT_BONES, {id: i, scale: 1}) for i = 14, 28

PPM2.PonyWeightController = PonyWeightController
PPM2.NewPonyWeightController = NewPonyWeightController
PPM2.GetPonyWeightController = (model = '') -> PonyWeightController.AVALIABLE_CONTROLLERS[model] or PonyWeightController
