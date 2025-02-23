#include "dragdrop.h"
#include "cinder/Log.h"

using namespace ci;
using namespace emscripten;
using namespace std;
	EMSCRIPTEN_BINDINGS( CinderEEmscripten ) {
		emscripten::class_<std::function<void( emscripten::val e )> >( "Lislback" )
		.constructor<>()
		.function( "onload", &std::function<void( emscripten::val e )>::operator());
	};

DragDrop::DragDrop( std::string elId, std::function<void(emscripten::val)> onProcess ):
mEl( emscripten::val::undefined() ),
mFile( emscripten::val::undefined() )
{

    // query element
    mEl = em::helpers::querySelector( elId );    

    this->onProcess = onProcess;

    // if element is null, log and bail out. 
    if( mEl == val::null() )
    {
        CI_LOG_I( "Cannot set up drag and drop - the element does not exist" );
        return;
    }

    setup();
}

void DragDrop::setOnDrop( std::function<void( emscripten::val )> onDrop )
{
    this->onDrop = onDrop;
    setup();
}

// ========================= //

void DragDrop::setup()
{
    // setup default handler for when things are dropped onto canvas. 
    // This assumes that only one item is being dropped at a time, if you need to handle more
    // than one file, add your own drop handler.  
    std::function<void(emscripten::val)> func = onProcess;     

    onDrop = [func]( emscripten::val e )-> void {
        e.call<void>( "preventDefault" );

   
         // if there are items being dropped
        if( e["dataTransfer"]["items"].as<bool>() )
        {

            // loop through and process whatever the last file was that was dropped. 
            auto len = e["dataTransfer"]["items"]["length"].as<int>();
      
            for(int i = 0; i < len; ++i){
                emscripten::val itm = e["dataTransfer"]["items"][i];

                // if the itm dropped is classified as file, set that to be the current item.
                if( itm["kind"].as<string>() == "file" )
                {
                  
                   func( itm.call<val>( "getAsFile" ) );
                }
            }
        }
    };
                                   
    // need to set this up to stop default browser functionality. 
    onDragOver = []( emscripten::val e )-> void {
        e.call<void>( "preventDefault" );
    };


    // TEMP - need to figure out why Embind call at the top of the page isn't getting compiled in. 
	auto functor_adapter = emscripten::val( onDrop )[ "onload" ].call<emscripten::val>( "bind", emscripten::val(onDrop) );
    auto functor_adapter2 = emscripten::val( onDrop )[ "onload" ].call<emscripten::val>( "bind", emscripten::val(onDrop) );

    mEl.set( "ondrop" , functor_adapter);
    mEl.set( "ondragover" , functor_adapter2 );
}