#ifndef CLIBVLC_SHIM_H
#define CLIBVLC_SHIM_H

#include <stdint.h>

// --- Opaque types ---

typedef struct libvlc_instance_t libvlc_instance_t;
typedef struct libvlc_media_t libvlc_media_t;
typedef struct libvlc_media_player_t libvlc_media_player_t;
typedef struct libvlc_event_manager_t libvlc_event_manager_t;
typedef int64_t libvlc_time_t;

// --- Track description ---

typedef struct libvlc_track_description_t {
    int i_id;
    char *psz_name;
    struct libvlc_track_description_t *p_next;
} libvlc_track_description_t;

// --- Media parse flags ---

typedef enum libvlc_media_parse_flag_t {
    libvlc_media_parse_local   = 0x00,
    libvlc_media_parse_network = 0x01,
    libvlc_media_fetch_local   = 0x02,
    libvlc_media_fetch_network = 0x04,
    libvlc_media_do_interact   = 0x08
} libvlc_media_parse_flag_t;

// --- Media state ---

typedef enum libvlc_state_t {
    libvlc_NothingSpecial = 0,
    libvlc_Opening,
    libvlc_Buffering,
    libvlc_Playing,
    libvlc_Paused,
    libvlc_Stopped,
    libvlc_Ended,
    libvlc_Error
} libvlc_state_t;

// --- Event types ---

enum {
    libvlc_MediaPlayerMediaChanged    = 0x100,
    libvlc_MediaPlayerNothingSpecial  = 0x101,
    libvlc_MediaPlayerOpening         = 0x102,
    libvlc_MediaPlayerBuffering       = 0x103,
    libvlc_MediaPlayerPlaying         = 0x104,
    libvlc_MediaPlayerPaused          = 0x105,
    libvlc_MediaPlayerStopped         = 0x106,
    libvlc_MediaPlayerForward         = 0x107,
    libvlc_MediaPlayerBackward        = 0x108,
    libvlc_MediaPlayerEndReached      = 0x109,
    libvlc_MediaPlayerEncounteredError = 0x10A,
    libvlc_MediaPlayerTimeChanged     = 0x10B,
    libvlc_MediaPlayerPositionChanged = 0x10C,
    libvlc_MediaPlayerSeekableChanged = 0x10D,
    libvlc_MediaPlayerPausableChanged = 0x10E,
    libvlc_MediaPlayerTitleChanged    = 0x10F,
    libvlc_MediaPlayerSnapshotTaken   = 0x110,
    libvlc_MediaPlayerLengthChanged   = 0x111,
    libvlc_MediaPlayerVout            = 0x112,
    libvlc_MediaPlayerMuted           = 0x113,
    libvlc_MediaPlayerUnmuted         = 0x114,
    libvlc_MediaPlayerAudioVolume     = 0x115
};

// --- Event structure ---

typedef struct libvlc_event_t {
    int type;
    void *p_obj;
    union {
        struct { float new_position; } media_player_position_changed;
        struct { libvlc_time_t new_time; } media_player_time_changed;
        struct { float new_cache; } media_player_buffering;
        struct { int new_seekable; } media_player_seekable_changed;
        struct { libvlc_time_t new_length; } media_player_length_changed;
        struct { float volume; } media_player_audio_volume;
        struct { int new_count; } media_player_vout;
    } u;
} libvlc_event_t;

// --- Callback type ---

typedef void (*libvlc_callback_t)(const libvlc_event_t *p_event, void *p_data);

// --- Core ---

libvlc_instance_t *libvlc_new(int argc, const char *const *argv);
void libvlc_release(libvlc_instance_t *p_instance);
const char *libvlc_get_version(void);

// --- Media ---

libvlc_media_t *libvlc_media_new_path(libvlc_instance_t *p_instance, const char *path);
libvlc_media_t *libvlc_media_new_location(libvlc_instance_t *p_instance, const char *psz_mrl);
void libvlc_media_release(libvlc_media_t *p_md);
int libvlc_media_parse_with_options(libvlc_media_t *p_md, libvlc_media_parse_flag_t parse_flag, int timeout);
libvlc_time_t libvlc_media_get_duration(libvlc_media_t *p_md);
libvlc_state_t libvlc_media_get_state(libvlc_media_t *p_md);
char *libvlc_media_get_meta(libvlc_media_t *p_md, int e_meta);
void libvlc_media_add_option(libvlc_media_t *p_md, const char *psz_options);

// --- Media Player ---

libvlc_media_player_t *libvlc_media_player_new(libvlc_instance_t *p_instance);
libvlc_media_player_t *libvlc_media_player_new_from_media(libvlc_media_t *p_md);
void libvlc_media_player_release(libvlc_media_player_t *p_mp);
void libvlc_media_player_set_media(libvlc_media_player_t *p_mp, libvlc_media_t *p_md);
libvlc_media_t *libvlc_media_player_get_media(libvlc_media_player_t *p_mp);

void libvlc_media_player_set_nsobject(libvlc_media_player_t *p_mp, void *drawable);
void *libvlc_media_player_get_nsobject(libvlc_media_player_t *p_mp);

int libvlc_media_player_play(libvlc_media_player_t *p_mp);
void libvlc_media_player_pause(libvlc_media_player_t *p_mp);
void libvlc_media_player_stop(libvlc_media_player_t *p_mp);
void libvlc_media_player_set_pause(libvlc_media_player_t *p_mp, int do_pause);

int libvlc_media_player_is_playing(libvlc_media_player_t *p_mp);
libvlc_state_t libvlc_media_player_get_state(libvlc_media_player_t *p_mp);

float libvlc_media_player_get_position(libvlc_media_player_t *p_mp);
void libvlc_media_player_set_position(libvlc_media_player_t *p_mp, float f_pos);

libvlc_time_t libvlc_media_player_get_time(libvlc_media_player_t *p_mp);
void libvlc_media_player_set_time(libvlc_media_player_t *p_mp, libvlc_time_t i_time);

libvlc_time_t libvlc_media_player_get_length(libvlc_media_player_t *p_mp);

float libvlc_media_player_get_rate(libvlc_media_player_t *p_mp);
int libvlc_media_player_set_rate(libvlc_media_player_t *p_mp, float rate);

int libvlc_media_player_will_play(libvlc_media_player_t *p_mp);
int libvlc_media_player_is_seekable(libvlc_media_player_t *p_mp);
int libvlc_media_player_can_pause(libvlc_media_player_t *p_mp);

// --- Audio ---

int libvlc_audio_get_volume(libvlc_media_player_t *p_mp);
int libvlc_audio_set_volume(libvlc_media_player_t *p_mp, int i_volume);
int libvlc_audio_get_mute(libvlc_media_player_t *p_mp);
void libvlc_audio_set_mute(libvlc_media_player_t *p_mp, int status);
int libvlc_audio_get_track_count(libvlc_media_player_t *p_mp);
int libvlc_audio_get_track(libvlc_media_player_t *p_mp);
int libvlc_audio_set_track(libvlc_media_player_t *p_mp, int i_track);
libvlc_track_description_t *libvlc_audio_get_track_description(libvlc_media_player_t *p_mp);
int libvlc_audio_get_delay(libvlc_media_player_t *p_mp);
int libvlc_audio_set_delay(libvlc_media_player_t *p_mp, int64_t i_delay);

// --- Video / Subtitles ---

int libvlc_video_get_spu_count(libvlc_media_player_t *p_mp);
int libvlc_video_get_spu(libvlc_media_player_t *p_mp);
int libvlc_video_set_spu(libvlc_media_player_t *p_mp, int i_spu);
libvlc_track_description_t *libvlc_video_get_spu_description(libvlc_media_player_t *p_mp);
int libvlc_video_set_subtitle_file(libvlc_media_player_t *p_mp, const char *psz_subtitle);
int64_t libvlc_video_get_spu_delay(libvlc_media_player_t *p_mp);
int libvlc_video_set_spu_delay(libvlc_media_player_t *p_mp, int64_t i_delay);

int libvlc_video_get_size(libvlc_media_player_t *p_mp, unsigned num, unsigned *px, unsigned *py);
float libvlc_video_get_scale(libvlc_media_player_t *p_mp);
void libvlc_video_set_scale(libvlc_media_player_t *p_mp, float f_factor);
int libvlc_video_get_track_count(libvlc_media_player_t *p_mp);
int libvlc_video_get_track(libvlc_media_player_t *p_mp);
int libvlc_video_set_track(libvlc_media_player_t *p_mp, int i_track);
int libvlc_video_take_snapshot(libvlc_media_player_t *p_mp, unsigned num,
                                const char *psz_filepath, unsigned int i_width, unsigned int i_height);

// --- Track descriptions ---

void libvlc_track_description_list_release(libvlc_track_description_t *p_track_description);

// --- Events ---

libvlc_event_manager_t *libvlc_media_player_event_manager(libvlc_media_player_t *p_mp);
int libvlc_event_attach(libvlc_event_manager_t *p_event_manager,
                         int i_event_type,
                         libvlc_callback_t f_callback,
                         void *user_data);
void libvlc_event_detach(libvlc_event_manager_t *p_event_manager,
                          int i_event_type,
                          libvlc_callback_t f_callback,
                          void *user_data);

// --- Media meta types ---

enum {
    libvlc_meta_Title = 0,
    libvlc_meta_Artist,
    libvlc_meta_Genre,
    libvlc_meta_Copyright,
    libvlc_meta_Album,
    libvlc_meta_TrackNumber,
    libvlc_meta_Description,
    libvlc_meta_Rating,
    libvlc_meta_Date,
    libvlc_meta_Setting,
    libvlc_meta_URL,
    libvlc_meta_Language,
    libvlc_meta_NowPlaying,
    libvlc_meta_Publisher,
    libvlc_meta_EncodedBy,
    libvlc_meta_ArtworkURL,
    libvlc_meta_TrackID,
    libvlc_meta_TrackTotal,
    libvlc_meta_Director,
    libvlc_meta_Season,
    libvlc_meta_Episode,
    libvlc_meta_ShowName,
    libvlc_meta_Actors,
    libvlc_meta_AlbumArtist,
    libvlc_meta_DiscNumber,
    libvlc_meta_DiscTotal
};

#endif /* CLIBVLC_SHIM_H */
