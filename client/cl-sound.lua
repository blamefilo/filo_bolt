local function loadAudioFile()
    if not RequestScriptAudioBank('audiodirectory/filo_bolt_sounds', false) then
        while not RequestScriptAudioBank('audiodirectory/filo_bolt_sounds', false) do
            Wait(0)
        end
    end

    return true
end

function PlaySound(entity, soundName)
    loadAudioFile()

    local soundId = GetSoundId()
    PlaySoundFromEntity(soundId, soundName, entity, 'filo_bolt_soundset', false, 0)
    ReleaseSoundId(soundId)
    ReleaseNamedScriptAudioBank('audiodirectory/filo_bolt_sounds')
end
