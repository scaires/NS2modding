// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\DSPEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// From FMOD documentation:
//
// DSP_Mixer        This unit does nothing but take inputs and mix them together then feed the result to the soundcard unit.
// DSP_Oscillator   This unit generates sine/square/saw/triangle or noise tones.
// DSP_LowPass      This unit filters sound using a high quality, resonant lowpass filter algorithm but consumes more CPU time.
// DSP_ITLowPass    This unit filters sound using a resonant lowpass filter algorithm that is used in Impulse Tracker, but with limited cutoff range (0 to 8060hz).
// DSP_HighPass     This unit filters sound using a resonant highpass filter algorithm.
// DSP_Echo         This unit produces an echo on the sound and fades out at the desired rate.
// DSP_Flange       This unit produces a flange effect on the sound.
// DSP_Distortion   This unit distorts the sound.
// DSP_Normalize    This unit normalizes or amplifies the sound to a certain level.
// DSP_ParamEQ      This unit attenuates or amplifies a selected frequency range.
// DSP_PitchShift   This unit bends the pitch of a sound without changing the speed of playback.
// DSP_Chorus       This unit produces a chorus effect on the sound.
// DSP_Reverb       This unit produces a reverb effect on the sound.
// DSP_VSTPlugin    This unit allows the use of Steinberg VST plugins.
// DSP_WinampPlugin This unit allows the use of Nullsoft Winamp plugins.
// DSP_ITEcho       This unit produces an echo on the sound and fades out at the desired rate as is used in Impulse Tracker.
// DSP_Compressor   This unit implements dynamic compression (linked multichannel, wideband).
// DSP_SFXReverb    This unit implements SFX reverb.
// DSP_LowPassSimple This unit filters sound using a simple lowpass with no resonance, but has flexible cutoff and is fast.
// DSP_Delay            This unit produces different delays on individual channels of the sound.
// DSP_Tremolo      This unit produces a tremolo/chopper effect on the sound.
//            
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Look at kDSPType
function CreateDSPs()

    local dspId = Client.CreateDSP(SoundSystem.DSP_LowPassSimple)
    
    
    // "NearDeath"
    // Simon - Near-death effect low-pass filter
    Client.SetDSPFloatParameter(dspId, 0, 2738)
    
    if dspId ~= kDSPType.NearDeath then
        Print("CreateDSPs(): NearDeath DSP id is %d instead of %d", dspId, kDSPType.NearDeath)
    end
    
    
    // "ShadeDisorientFlange"
    dspId = Client.CreateDSP(SoundSystem.DSP_Flange)
    
    // Simon - Shade disorient drymix
    Client.SetDSPFloatParameter(dspId, 0, .922)
    // Simon - Shade disorient wetmix
    Client.SetDSPFloatParameter(dspId, 1, .766)
    // Simon - Shade disorient depth
    Client.SetDSPFloatParameter(dspId, 2, .550)
    // Simon - Shade disorient rate
    Client.SetDSPFloatParameter(dspId, 3,  0.6)
    
    if dspId ~= kDSPType.ShadeDisorientFlange then
        Print("CreateDSPs(): ShadeDisorientFlange DSP id is %d instead of %d", dspId, kDSPType.ShadeDisorientFlange)
    end    


    // "ShadeDisorientLoPass"
    dspId = Client.CreateDSP(SoundSystem.DSP_LowPassSimple)

    // Simon - Shade disorient low-pass filter
    Client.SetDSPFloatParameter(dspId, 0, 533)
    
    if dspId ~= kDSPType.ShadeDisorientLoPass then
        Print("CreateDSPs(): ShadeDisorientLoPass DSP id is %d instead of %d", dspId, kDSPType.ShadeDisorientLoPass)
    end    
    
end

function UpdateDSPEffects()

    local player = Client.GetLocalPlayer()
    
    // Near death
    Client.SetDSPActive(kDSPType.NearDeath, player:GetGameEffectMask(kGameEffect.NearDeath))
    
    // Shade disorientation uses both of these
    Client.SetDSPActive(kDSPType.ShadeDisorientFlange, player:GetGameEffectMask(kGameEffect.Disorient))
    Client.SetDSPActive(kDSPType.ShadeDisorientLoPass, player:GetGameEffectMask(kGameEffect.Disorient))
    
end
