#ifndef ENABLE_FFMPEG
#define ENABLE_FFMPEG 1
#endif

#if ENABLE_FFMPEG == 1
require ffmpeg

record_region(){
    path=`maketemp mp4`

    case `getconfiguration SELECTION_METHOD` in
        dark)
            geometry=`select_dark`
            ;;
        light)
            geometry=`select_light`
            ;;
        *)
            geometry=`select_default`
            ;;
    esac
    sleep 0.1

    [[ -z "${geometry}" ]] && exit 0

    read -r width height x y <<< ${geometry}

    ffmpeg -f x11grab -s ${width}x${height} -i :0.0+${x},${y} \
        -vcodec libx264 -preset veryfast \
        -tune zerolatency -vsync 0 -y -loglevel 0 ${path}

    post ${path}
}

record_fullscreen(){
    path=`maketemp mp4`
    geometry=`select_root_window`
    read -r width height x y <<< ${geometry}

    ffmpeg -f x11grab -s ${width}x${height} -i :0.0+0,0 \
        -vcodec libx264 -preset veryfast \
        -tune zerolatency -vsync 0 -y -loglevel 0 ${path}

    post ${path}
}

record_focused_monitor(){
    path=`maketemp mp4`

    geometry=`select_focused_monitor`
    read -r width height x y <<< ${geometry}

    ffmpeg -f x11grab -s ${width}x${height} -i :0.0+${x},${y} \
        -vcodec libx264 -preset veryfast \
        -tune zerolatency -vsync 0 -y -loglevel 0 ${path}

    post ${path}
}
#else
record_region(){}
record_fullscreen(){}
record_focused_monitor(){}
#endif

