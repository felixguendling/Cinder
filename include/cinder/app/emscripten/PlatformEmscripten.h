/*
 Copyright (c) 2012, The Cinder Project, All rights reserved.

 This code is intended for use with the Cinder C++ library: http://libcinder.org

 Redistribution and use in source and binary forms, with or without modification, are permitted provided that
 the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and
	the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
	the following disclaimer in the documentation and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
*/

#pragma once

#include "cinder/app/Platform.h"

namespace cinder { namespace app {

class PlatformEmscripten : public Platform 
{
 public:

	PlatformEmscripten();
	virtual ~PlatformEmscripten();

	static PlatformEmscripten*			get();

	virtual void 					cleanupLaunch() override;

	virtual DataSourceRef			loadResource( const fs::path &resourcePath ) override;
  	virtual DataSourceRef			loadAsset( const fs::path &resourcePath ) override;

	virtual fs::path				getResourceDirectory() const override;
	virtual fs::path				getResourcePath( const fs::path &rsrcRelativePath ) const override;

	virtual fs::path 				getOpenFilePath( const fs::path &initialPath, const std::vector<std::string> &extensions ) override;
	virtual fs::path 				getFolderPath( const fs::path &initialPath ) override;
	virtual fs::path 				getSaveFilePath( const fs::path &initialPath, const std::vector<std::string> &extensions ) override;

	virtual std::map<std::string, std::string>	getEnvironmentVariables() override;

	virtual fs::path				expandPath( const fs::path &path ) override;
	virtual fs::path				getHomeDirectory() const override;
	virtual fs::path				getDocumentsDirectory() const override;
	virtual fs::path				getDefaultExecutablePath() const override;

	virtual void 					sleep( float milliseconds ) override;
	void setThreadName( const std::string &name ) override;
	virtual void 					launchWebBrowser( const Url &url ) override;

	virtual std::vector<std::string>		stackTrace() override;
	virtual const std::vector<DisplayRef>&	getDisplays() override;

 private:
	bool							mDisplaysInitialized = false;
	std::vector<DisplayRef>			mDisplays;
	mutable std::vector<fs::path>	mResourceDirectories;
	mutable bool					mResourceDirsInitialized = false;
};

}} // namespace cinder::app
