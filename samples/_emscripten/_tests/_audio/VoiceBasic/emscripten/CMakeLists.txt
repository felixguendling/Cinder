cmake_minimum_required( VERSION 2.8 FATAL_ERROR )
set( CMAKE_VERBOSE_MAKEFILE ON )

project( VoiceBasic )

get_filename_component( CINDER_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../" ABSOLUTE )
get_filename_component( APP_PATH "${CMAKE_CURRENT_SOURCE_DIR}../../" ABSOLUTE )

include( "${CINDER_PATH}/proj/cmake/modules/cinderEmscriptenApp.cmake" )

ci_emscripten_app(
	SOURCES     ${APP_PATH}/src/VoiceBasic.cpp ../../EmscriptenAudio/ContextWebAudio.cpp ../../EmscriptenAudio/Voice.cpp
	CINDER_PATH ${CINDER_PATH}
	INCLUDES ../../EmscriptenAudio
	ASSETS ../assets
)
