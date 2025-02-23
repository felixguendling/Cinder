# TODO
# 1. Add CinderBlock support - not sure what the best way is at the moment.

function(ci_emscripten_app)
    set( oneValueArgs

            # the path to Cinder installation
            CINDER_PATH

            # path to your assets folder. 
            ASSETS

            MEMORY_DEBUG

            )
    set( multiValueArgs

            # a path to a custom HTML template
            # See https://kripken.github.io/emscripten-site/docs/tools_reference/emcc.html#emcc-shell-file for details.
            HTML_TEMPLATE

            # a list of source files to use in the build. Typically you'll only need to list your main app file.
            SOURCES

            # a list of header files to include in the build
            INCLUDES

            # a list of library paths that you would like to include in the build.
            LIBRARIES

            # any additional non-standard flags you may want to include
            FLAGS

            # tells emscripten to include use of threads. Note that this requires use of SharedArrayBuffers - check your
            # browser for how to enable, if it's possible.
            THREADS

            # Thread pool size - this indicates the number of threads you'd like to pre-allocate.
            # note that it is apparently better to pre-allocate then dynamically generate.
            THREAD_POOL_SIZE

            # Thread hint num cores
            THREAD_NUM_CORES

            # tells emscripten to use browser decoding
            BROWSER_DECODE

            # if your project is intended to be a web worker, this adds the necessary flags.
            BUILD_AS_WORKER

            # tells Emscripten what functions you want to expose to your main application within your worker.
            # the parameter should be a single quoted string with all functions separated by a comma ie
            # '_onmessage,_postmessage'
            EXPORT_FROM_WORKER

            # Tells Emscripten to not build with async libraries bundled.
            # note that this will disable ci::app::loadAsset and you will have to rely on async functions, native emscripten functions or write your own JS.
            NO_ASYNC

            # Sepecifies the type of build you want to do, either "Debug" or "Release"
            BUILD_TYPE

            # argument to tell emscripten to bundle resources
            RESOURCES

            # argument to tell what to name all the files it will output
            OUTPUT_NAME

            # in case you want to override the default output directory
            OUTPUT_DIRECTORY 
            )

    cmake_parse_arguments( ARG "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

    if( ARG_UNPARSED_ARGUMENTS )
        message( WARNING "unhandled arguments: ${ARG_UNPARSED_ARGUMENTS}" )
    endif()

	# https://blog.kitware.com/cmake-and-the-default-build-type/
	#
	# Set a default build type if none was specified
	set( default_build_type "Debug" )
	if( NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES )
		message(STATUS "Setting build type to '${default_build_type}' as none was specified.")
		set( CMAKE_BUILD_TYPE "${default_build_type}" CACHE
			STRING "Choose the type of build." FORCE )
		# Set the possible values of build type for cmake-gui
		set_property( CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
			"Debug" "Release" "MinSizeRel" "RelWithDebInfo" )
	endif()

	# Set CMAKE_RUNTIME_OUTPUT_DIRECTORY based on build type for single-config generator ( i.e Makefile ) otherwise ( i.e Xcode, VS )  use CMAKE_BINARY_DIR
	if( "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" STREQUAL "" )
		if( ( "${CMAKE_GENERATOR}" MATCHES "Visual Studio.+" ) OR ( "Xcode" STREQUAL "${CMAKE_GENERATOR}" ) )
			set( CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR} )
		else()
			# Append the build type to the output dir
			set( CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/${CMAKE_BUILD_TYPE} )
		endif()
	endif()

    if (ARG_OUTPUT_DIRECTORY)
		set( CMAKE_RUNTIME_OUTPUT_DIRECTORY ${ARG_OUTPUT_DIRECTORY} )
    endif()

    if(ARG_BUILD_AS_WORKER)
        set(WORKER_MESSAGE "YES")
    endif()


    # Log current settings
    message("\nCURRENT SETTINGS\n======")
    message( "APP_NAME: ${ARG_OUTPUT_NAME}" )
    message( "SOURCES: ${ARG_SOURCES}" )
    message( "INCLUDES: ${ARG_INCLUDES}" )
    message( "LIBRARIES: ${ARG_LIBRARIES}" )
    message( "CINDER_PATH: ${ARG_CINDER_PATH}" )
    message( "CMAKE_RUNTIME_OUTPUT_DIRECTORY: ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" )
    message( "CINDER_BUILD_TYPE: ${CMAKE_BUILD_TYPE}" )
    message( "BUILDING AS WEB WORKER: ${WORKER_MESSAGE}" )

    if (ARG_RESOURCES)
        message( "RESOURCES FOLDER IS SET TO ${ARG_RESOURCES}" )
    endif ()

    if (ARG_ASSETS)
        message("Assets folder is set to ${ARG_ASSETS}")
    endif ()
    message("\n")

    # ========= SETUP BUILD ============== #
    get_filename_component( CINDER_PATH "${ARG_CINDER_PATH}" ABSOLUTE PARENT_SCOPE)

	# Include Cinder and Emscripten variables
	include( "${CINDER_PATH}/proj/cmake/configure.cmake" )
	include( "${CINDER_PATH}/proj/cmake/platform_emscripten.cmake" )

	# set variable for helper file when handling DOM related stuff. This should be a part of the --pre-js Emscripten flag
	set( CINDER_JS_HELPERS "--pre-js ${CINDER_PATH}/include/cinder/emscripten/helpers.js" )

    # this is important, if not set you will only get JS files.
    if(NOT ARG_BUILD_AS_WORKER)
        set(CMAKE_EXECUTABLE_SUFFIX ".html" PARENT_SCOPE)
    endif()

    # append core flags
    set(CXX_FLAGS "${CXX_FLAGS} --bind")

    if(NOT ARG_BUILD_AS_WORKER)
        set(CXX_FLAGS "${CXX_FLAGS} ${CINDER_JS_HELPERS}")
    endif()

    # if user wants to build as a worker
    if (ARG_BUILD_AS_WORKER)
    
      set(CXX_FLAGS "${CXX_FLAGS} -s BUILD_AS_WORKER=1")
    endif()

    # trying to set memory growth to be on by default.
    set(CXX_FLAGS "${CXX_FLAGS} -s ALLOW_MEMORY_GROWTH=1")

    if(ARG_BUILD_AS_WORKER)
        if(ARG_EXPORT_FROM_WORKER)
            set(CXX_FLAGS "${CXX_FLAGS} -s EXPORTED_FUNCTIONS=[${ARG_EXPORT_FROM_WORKER}]")
        else()
            message(ERROR " In order to use web workers, you need to expose functions from your worker to your main application" )
        endif()
    endif()

   
   # New WASM oriented backend(as of 10/2019) for Emscripten requires you to set stack size to something at least greater than 10000
   # TODO may need to experiement to find a more logical value, currently can't seem to find information regarding what the value is measured in.
    if(ARG_BUILD_AS_WORKER OR ARG_NO_ASYNC)
       set( CXX_FLAGS "${CXX_FLAGS} -s ASYNCIFY=0 -s ASYNCIFY_STACK_SIZE=0" )
    elseif( NOT ARG_NO_ASYNC )
        set( CXX_FLAGS "${CXX_FLAGS} -s ASYNCIFY=1 -s ASYNCIFY_STACK_SIZE=60000" )
    endif()

    # if custom html template is wanted, use that, otherwise, use default
    if(ARG_HTML_TEMPLATE)
        set(CXX_FLAGS "${CXX_FLAGS} --shell-file ${ARG_HTML_TEMPLATE}")
    else()
        set( CXX_FLAGS "${CXX_FLAGS} --shell-file ${CINDER_PATH}/proj/cmake/emscripten/shell.html" )
    endif()

    # if we need assertations set flags
    if(ARG_MEMORY_DEBUG)
        set(CXX_FLAGS "${CXX_FLAGS} -s ASSERTIONS=1 -s SAFE_HEAP=1")
    endif()

    # if FLAGS parameter is set, append additional flags.
    if(ARG_FLAGS)
        set(CXX_FLAGS "${CXX_FLAGS} ${ARG_FLAGS}")
    endif()

     # if building release add some extra flags to optimize final bundle.
    # see https://kripken.github.io/emscripten-site/docs/optimizing/Optimizing-Code.html for other tips on optimizing code.
    if( "Release" STREQUAL "${CMAKE_BUILD_TYPE}" )
        set( CXX_FLAGS "${CXX_FLAGS} ${CMAKE_CXX_FLAGS_RELEASE}" )
        set( CXX_FLAGS "${CXX_FLAGS} ${ADD_OPTIMIZATIONS}" )
        set( CXX_FLAGS "${CXX_FLAGS} ${CMAKE_CXX_FLAGS_RELEASE}" )
        list( APPEND EMCC_CLOSURE_ARGS "--externs ${CINDER_PATH}/include/cinder/emscripten/externs.js" )
    endif()

    # =========== ADD OTHER OPTIONAL FLAGS ================ #

    # if we have resources to bundle, build and append flags for that
    if (ARG_RESOURCES)
        message(WARNING "Note that some resources(really large media files), while it is possible to bundle, they may not load as expected. It would be better to use native JS based methods to load instead." )
        set(CXX_FLAGS "${CXX_FLAGS} --preload-file ${ARG_RESOURCES}@")
    endif ()


    # if user wants to use browser for decoding media.
    if(ARG_BROWSER_DECODE)
      set(CXX_FLAGS "${CXX_FLAGS} ${USE_BROWSER_FOR_DECODING}")
    endif()


  # if user wants threading support.
    if(ARG_THREADS)
        message(STATUS "Note that threads require SharedArrayBuffer object which may/may not be disabled in your browser. \n See https://kripken.github.io/emscripten-site/docs/porting/pthreads.html for more information.")
        set(CXX_FLAGS "${CXX_FLAGS} ${USE_THREADS}")

        if( NOT ARG_THREAD_POOL_SIZE )
            set(CXX_FLAGS "${CXX_FLAGS} -s PTHREAD_POOL_SIZE=-1")
        endif()

        if( NOT ARG_THREAD_NUM_CORES )
            set(CXX_FLAGS "${CXX_FLAGS} -s PTHREAD_HINT_NUM_CORES=-1")
        endif()
    endif()

    message("Current flags for build are : \n ${CXX_FLAGS} \n")


    # ========== COMPILE ALL FLAGS TOGETHER ============== #

    # compile all necessary flags
    set(CMAKE_EXE_LINKER_FLAGS "${CXX_FLAGS} ${CINDER_EMSCRIPTEN_LINK_FLAGS}" PARENT_SCOPE)

	# This ensures that the application will link with the correct version of Cinder
	# based on the current build type without the need to remove the entire build folder
	# when switching build type after an initial configuration. See PR #1518 for more info.
	if( cinder_DIR )
		unset( cinder_DIR CACHE )
	endif()

    # ========= COMPILE ALL BUILD PARAMETERS TOGETHER ============= #
	if( NOT TARGET cinder )
		find_package( cinder REQUIRED PATHS
			"${CINDER_PATH}/${CINDER_LIB_DIRECTORY}"
			"$ENV{CINDER_PATH}/${CINDER_LIB_DIRECTORY}"
			NO_CMAKE_FIND_ROOT_PATH
		)
	endif()

    if(ARG_OUTPUT_NAME)
        set(OUTPUT_NAME "${ARG_OUTPUT_NAME}")
    else()
        set(OUTPUT_NAME "index")
    endif()

    add_executable(${OUTPUT_NAME} ${ARG_SOURCES} )

    target_include_directories(
            ${OUTPUT_NAME}
            # TODO check to if PUBLIC specifier works if multiple files are specified, otherwise we'll need to manually do this.
            PUBLIC ${ARG_INCLUDES}
    )

    # if a specific output directory is specified make sure to tell cmake
    if(ARG_OUTPUT_DIRECTORY)
        set_target_properties(${OUTPUT_NAME}  PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${ARG_OUTPUT_DIRECTORY})
    endif()
	

    target_link_libraries(
            ${OUTPUT_NAME}
            #${EMSCRIPTEN_LIB_DIRECTORY}/libboost_filesystem.bc
            #${EMSCRIPTEN_LIB_DIRECTORY}/libboost_system.bc
			cinder
            ${ARG_LIBRARIES}
    )

    # copy assets to build folder.
    if( ARG_ASSETS )
        file( INSTALL ${ARG_ASSETS} DESTINATION "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}" )
    endif()


endfunction()
