#!/bin/bash
# Media Downloader Application Packaging Script
# Creates a complete application structure for distribution

# Create the application directory structure
mkdir -p media-downloader-app/{
    src/mediadownloader,
    data/{icons,applications,metainfo},
    scripts,
    docs,
    tests
}

cd media-downloader-app

# Create the main Python package structure
cat > src/mediadownloader/__init__.py << 'EOF'
"""
Media Downloader - Combined Audio/Video Downloader
A modern media downloader with GUI and CLI interfaces
"""

__version__ = "1.0.0"
__author__ = "Media Downloader Team"
__license__ = "GPL-3.0"

from .downloader import MediaDownloader
from .gui import DownloaderGUI
from .cli import DownloaderCLI

__all__ = ['MediaDownloader', 'DownloaderGUI', 'DownloaderCLI']
EOF

# Create the main downloader module
cat > src/mediadownloader/downloader.py << 'EOF'
#!/usr/bin/env python3
"""
Core media downloader functionality
"""

import yt_dlp
import os
import sys
from pathlib import Path

class MediaDownloader:
    def __init__(self):
        self.system_info = self.get_system_info()
        
    def get_system_info(self):
        """Get Linux system information"""
        try:
            session_type = os.environ.get('XDG_SESSION_TYPE', 'unknown')
            desktop = os.environ.get('XDG_CURRENT_DESKTOP', 'unknown')
            return {
                'session_type': session_type,
                'desktop': desktop,
                'home': os.path.expanduser('~')
            }
        except:
            return {
                'session_type': 'unknown',
                'desktop': 'unknown', 
                'home': os.path.expanduser('~')
            }
    
    def check_dependencies(self):
        """Check if yt-dlp is installed"""
        try:
            import yt_dlp
            return True, "All dependencies found!"
        except ImportError:
            error_msg = """yt-dlp is not installed.

Installation options for Fedora:
1. Using DNF (recommended):
   sudo dnf install yt-dlp

2. Using pip (user installation):
   pip install --user yt-dlp

3. Using Flatpak:
   flatpak install flathub org.videolan.VLC"""
            return False, error_msg
    
    def get_video_info(self, url):
        """Get video information without downloading"""
        try:
            ydl_opts = {'quiet': True, 'no_warnings': True}
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(url, download=False)
                return {
                    'title': info.get('title', 'Unknown'),
                    'uploader': info.get('uploader', 'Unknown'),
                    'duration': info.get('duration', 'Unknown'),
                    'view_count': info.get('view_count', 'Unknown'),
                    'upload_date': info.get('upload_date', 'Unknown'),
                    'formats': info.get('formats', [])
                }
        except Exception as e:
            raise Exception(f"Error getting video info: {str(e)}")
    
    def download_media(self, url, output_dir, download_type='video', video_format='mp4', 
                      quality='worst[height>=1080]', audio_format='mp3', audio_quality='5',
                      download_subs=False, download_thumb=False, progress_callback=None):
        """Download media with specified options"""
        
        # Create output directory
        try:
            os.makedirs(output_dir, mode=0o755, exist_ok=True)
        except Exception as e:
            raise Exception(f"Error creating directory: {e}")
        
        # Configure yt-dlp options
        if download_type == 'audio':
            ydl_opts = {
                'format': 'bestaudio/best',
                'extractaudio': True,
                'audioformat': audio_format,
                'audioquality': audio_quality,
                'outtmpl': os.path.join(output_dir, '%(title)s.%(ext)s'),
                'noplaylist': True,
            }
        else:  # video
            ydl_opts = {
                'format': f'{quality}[ext={video_format}]/best[ext={video_format}]/{quality}/best',
                'outtmpl': os.path.join(output_dir, '%(title)s.%(ext)s'),
                'noplaylist': True,
            }
        
        # Add optional features
        if download_subs:
            ydl_opts['writesubtitles'] = True
            ydl_opts['writeautomaticsub'] = True
            ydl_opts['subtitleslangs'] = ['en', 'en-US', 'en-GB']
        
        if download_thumb:
            ydl_opts['writethumbnail'] = True
        
        # Add progress hook
        if progress_callback:
            ydl_opts['progress_hooks'] = [progress_callback]
        
        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                ydl.download([url])
            return True, "Download completed successfully!"
        except Exception as e:
            return False, f"Download failed: {str(e)}"
EOF

# Create setup.py for Python packaging
cat > setup.py << 'EOF'
#!/usr/bin/env python3
"""
Setup script for Media Downloader
"""

from setuptools import setup, find_packages
import os

# Read version from __init__.py
def get_version():
    version_file = os.path.join('src', 'mediadownloader', '__init__.py')
    with open(version_file, 'r') as f:
        for line in f:
            if line.startswith('__version__'):
                return line.split('=')[1].strip().strip('"\'')
    return '1.0.0'

# Read README
def get_long_description():
    try:
        with open('README.md', 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        return "A modern media downloader with GUI and CLI interfaces"

setup(
    name='media-downloader',
    version=get_version(),
    author='Media Downloader Team',
    author_email='support@example.com',
    description='A modern media downloader with GUI and CLI interfaces',
    long_description=get_long_description(),
    long_description_content_type='text/markdown',
    url='https://github.com/yourusername/media-downloader',
    package_dir={'': 'src'},
    packages=find_packages(where='src'),
    classifiers=[
        'Development Status :: 4 - Beta',
        'Intended Audience :: End Users/Desktop',
        'License :: OSI Approved :: GNU General Public License v3 (GPLv3)',
        'Operating System :: POSIX :: Linux',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
        'Topic :: Multimedia :: Video',
        'Topic :: Internet :: WWW/HTTP',
    ],
    python_requires='>=3.8',
    install_requires=[
        'yt-dlp>=2023.1.6',
    ],
    extras_require={
        'gui': ['tkinter'],  # Usually included with Python
    },
    entry_points={
        'console_scripts': [
            'media-downloader=mediadownloader.main:main',
            'media-downloader-gui=mediadownloader.main:gui_main',
            'media-downloader-cli=mediadownloader.main:cli_main',
        ],
        'gui_scripts': [
            'media-downloader-gui=mediadownloader.main:gui_main',
        ],
    },
    include_package_data=True,
    package_data={
        'mediadownloader': ['data/*'],
    },
    data_files=[
        ('share/applications', ['data/applications/com.example.MediaDownloader.desktop']),
        ('share/metainfo', ['data/metainfo/com.example.MediaDownloader.metainfo.xml']),
        ('share/icons/hicolor/scalable/apps', ['data/icons/com.example.MediaDownloader.svg']),
        ('share/icons/hicolor/256x256/apps', ['data/icons/com.example.MediaDownloader-256.png']),
        ('share/icons/hicolor/128x128/apps', ['data/icons/com.example.MediaDownloader-128.png']),
        ('share/icons/hicolor/64x64/apps', ['data/icons/com.example.MediaDownloader-64.png']),
        ('share/icons/hicolor/48x48/apps', ['data/icons/com.example.MediaDownloader-48.png']),
    ],
)
EOF

# Create desktop file for GNOME
cat > data/applications/com.example.MediaDownloader.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Media Downloader
GenericName=Video and Audio Downloader
Comment=Download videos and audio from 1000+ websites
Categories=AudioVideo;Video;Audio;Network;
Exec=media-downloader-gui
Icon=com.example.MediaDownloader
Terminal=false
StartupNotify=true
MimeType=x-scheme-handler/http;x-scheme-handler/https;
Keywords=download;video;audio;youtube;media;
StartupWMClass=Media Downloader
X-GNOME-UsesNotifications=true

[Desktop Action cli]
Name=Command Line Interface
Exec=media-downloader-cli
EOF

# Create AppStream metadata for GNOME Software
cat > data/metainfo/com.example.MediaDownloader.metainfo.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>com.example.MediaDownloader</id>
  
  <name>Media Downloader</name>
  <summary>Download videos and audio from 1000+ websites</summary>
  
  <description>
    <p>
      Media Downloader is a modern application that allows you to download videos and audio 
      from over 1000 websites including YouTube, Vimeo, Twitter, Instagram, and many more.
    </p>
    <p>
      Features:
    </p>
    <ul>
      <li>Clean, intuitive GUI interface</li>
      <li>Command-line interface for advanced users</li>
      <li>Multiple video formats (MP4, WebM, MKV, AVI, MOV)</li>
      <li>Multiple audio formats (MP3, M4A, OPUS, WAV, FLAC)</li>
      <li>Quality selection from 360p to best available</li>
      <li>Subtitle and thumbnail download support</li>
      <li>Real-time download progress</li>
      <li>Native Linux integration</li>
    </ul>
  </description>
  
  <metadata_license>CC0-1.0</metadata_license>
  <project_license>GPL-3.0-or-later</project_license>
  
  <categories>
    <category>AudioVideo</category>
    <category>Video</category>
    <category>Audio</category>
    <category>Network</category>
  </categories>
  
  <keywords>
    <keyword>download</keyword>
    <keyword>video</keyword>
    <keyword>audio</keyword>
    <keyword>youtube</keyword>
    <keyword>media</keyword>
  </keywords>
  
  <url type="homepage">https://github.com/yourusername/media-downloader</url>
  <url type="bugtracker">https://github.com/yourusername/media-downloader/issues</url>
  <url type="help">https://github.com/yourusername/media-downloader/wiki</url>
  
  <screenshots>
    <screenshot type="default">
      <caption>Main application window</caption>
      <image>https://example.com/screenshots/main-window.png</image>
    </screenshot>
    <screenshot>
      <caption>Download progress</caption>
      <image>https://example.com/screenshots/download-progress.png</image>
    </screenshot>
  </screenshots>
  
  <releases>
    <release version="1.0.0" date="2024-01-01">
      <description>
        <p>Initial release with GUI and CLI interfaces</p>
        <ul>
          <li>Modern tkinter GUI</li>
          <li>Command-line interface</li>
          <li>Support for 1000+ websites</li>
          <li>Multiple format support</li>
          <li>Quality selection</li>
          <li>Subtitle and thumbnail download</li>
        </ul>
      </description>
    </release>
  </releases>
  
  <provides>
    <binary>media-downloader</binary>
    <binary>media-downloader-gui</binary>
    <binary>media-downloader-cli</binary>
  </provides>
  
  <launchable type="desktop-id">com.example.MediaDownloader.desktop</launchable>
  
  <content_rating type="oars-1.1"/>
</component>
EOF

# Create main executable script
cat > src/mediadownloader/main.py << 'EOF'
#!/usr/bin/env python3
"""
Main entry point for Media Downloader
"""

import sys
import os

# Add the package to Python path if running from source
if __name__ == '__main__':
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

def gui_main():
    """Entry point for GUI version"""
    try:
        import tkinter as tk
        from .gui import DownloaderGUI
        from .downloader import MediaDownloader
        
        root = tk.Tk()
        app = DownloaderGUI(root)
        
        # Check dependencies
        deps_ok, deps_msg = app.downloader.check_dependencies()
        if not deps_ok:
            tk.messagebox.showerror("Dependencies Missing", deps_msg)
            root.destroy()
            return 1
        
        root.mainloop()
        return 0
    except ImportError as e:
        print(f"GUI not available: {e}")
        print("Install tkinter: sudo dnf install python3-tkinter")
        return 1
    except Exception as e:
        print(f"GUI failed: {e}")
        return 1

def cli_main():
    """Entry point for CLI version"""
    from .cli import DownloaderCLI
    
    cli = DownloaderCLI()
    cli.run()
    return 0

def main():
    """Main entry point - auto-detect best interface"""
    # Check for explicit CLI request
    if '--cli' in sys.argv or '--help' in sys.argv:
        return cli_main()
    
    # Try GUI first, fall back to CLI
    try:
        import tkinter
        return gui_main()
    except ImportError:
        print("GUI not available, using CLI mode")
        return cli_main()

if __name__ == '__main__':
    sys.exit(main())
EOF

# Create RPM spec file for Fedora packaging
cat > media-downloader.spec << 'EOF'
%global pypi_name media-downloader
%global python3_pkgversion 3

Name:           python-%{pypi_name}
Version:        1.0.0
Release:        1%{?dist}
Summary:        A modern media downloader with GUI and CLI interfaces

License:        GPLv3+
URL:            https://github.com/yourusername/media-downloader
Source0:        %{pypi_source}

BuildArch:      noarch

BuildRequires:  python%{python3_pkgversion}-devel
BuildRequires:  python%{python3_pkgversion}-setuptools
BuildRequires:  desktop-file-utils
BuildRequires:  libappstream-glib

Requires:       python%{python3_pkgversion}
Requires:       python%{python3_pkgversion}-tkinter
Requires:       yt-dlp

%description
Media Downloader is a modern application that allows you to download videos 
and audio from over 1000 websites including YouTube, Vimeo, Twitter, Instagram, 
and many more. Features both GUI and CLI interfaces.

%prep
%autosetup -n %{pypi_name}-%{version}

%build
%py3_build

%install
%py3_install

# Install desktop file
desktop-file-install --dir=%{buildroot}%{_datadir}/applications \
    data/applications/com.example.MediaDownloader.desktop

# Install appdata
mkdir -p %{buildroot}%{_datadir}/metainfo
install -pm 644 data/metainfo/com.example.MediaDownloader.metainfo.xml \
    %{buildroot}%{_datadir}/metainfo/

# Install icons (you'd need to create these)
mkdir -p %{buildroot}%{_datadir}/icons/hicolor/{scalable,256x256,128x128,64x64,48x48}/apps

%check
desktop-file-validate %{buildroot}%{_datadir}/applications/com.example.MediaDownloader.desktop
appstream-util validate-relax --nonet %{buildroot}%{_datadir}/metainfo/com.example.MediaDownloader.metainfo.xml

%files
%license LICENSE
%doc README.md
%{python3_sitelib}/mediadownloader/
%{python3_sitelib}/media_downloader-%{version}-py%{python3_version}.egg-info/
%{_bindir}/media-downloader
%{_bindir}/media-downloader-gui
%{_bindir}/media-downloader-cli
%{_datadir}/applications/com.example.MediaDownloader.desktop
%{_datadir}/metainfo/com.example.MediaDownloader.metainfo.xml
%{_datadir}/icons/hicolor/*/apps/com.example.MediaDownloader.*

%changelog
* Mon Jan 01 2024 Your Name <email@example.com> - 1.0.0-1
- Initial package
EOF

# Create Flatpak manifest for broader distribution
cat > com.example.MediaDownloader.json << 'EOF'
{
    "app-id": "com.example.MediaDownloader",
    "runtime": "org.gnome.Platform",
    "runtime-version": "45",
    "sdk": "org.gnome.Sdk",
    "command": "media-downloader-gui",
    "finish-args": [
        "--share=ipc",
        "--socket=fallback-x11",
        "--socket=wayland",
        "--device=dri",
        "--share=network",
        "--filesystem=xdg-download",
        "--filesystem=xdg-videos",
        "--filesystem=xdg-music"
    ],
    "modules": [
        {
            "name": "python3-yt-dlp",
            "buildsystem": "simple",
            "build-commands": [
                "pip3 install --verbose --exists-action=i --no-index --find-links=\"file://${PWD}\" --prefix=${FLATPAK_DEST} \"yt-dlp\""
            ],
            "sources": [
                {
                    "type": "file",
                    "url": "https://files.pythonhosted.org/packages/source/y/yt-dlp/yt-dlp-2024.1.7.tar.gz",
                    "sha256": "sha256-here"
                }
            ]
        },
        {
            "name": "media-downloader",
            "buildsystem": "simple",
            "build-commands": [
                "python3 setup.py install --prefix=${FLATPAK_DEST}"
            ],
            "sources": [
                {
                    "type": "dir",
                    "path": "."
                }
            ]
        }
    ]
}
EOF

# Create installation script
cat > scripts/install.sh << 'EOF'
#!/bin/bash
# Installation script for Media Downloader

set -e

echo "Installing Media Downloader..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "Don't run this as root. Install to user directory instead."
    exit 1
fi

# Install Python dependencies
echo "Installing dependencies..."
pip3 install --user yt-dlp

# Install the application
echo "Installing application..."
python3 setup.py install --user

# Install desktop files
echo "Installing desktop integration..."
mkdir -p ~/.local/share/applications
mkdir -p ~/.local/share/metainfo
mkdir -p ~/.local/share/icons/hicolor/scalable/apps

cp data/applications/com.example.MediaDownloader.desktop ~/.local/share/applications/
cp data/metainfo/com.example.MediaDownloader.metainfo.xml ~/.local/share/metainfo/

# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database ~/.local/share/applications
fi

echo "Installation complete!"
echo "You can now run 'media-downloader' or find 'Media Downloader' in your applications menu."
EOF

chmod +x scripts/install.sh

# Create README
cat > README.md << 'EOF'
# Media Downloader

A modern media downloader with GUI and CLI interfaces for Linux systems.

## Features

- **Dual Interface**: Both GUI and command-line interfaces
- **1000+ Sites**: Download from YouTube, Vimeo, Twitter, Instagram, and more
- **Multiple Formats**: Video (MP4, WebM, MKV) and Audio (MP3, M4A, OPUS, FLAC)
- **Quality Options**: From 360p to best available quality
- **Additional Features**: Subtitle and thumbnail downloads
- **Linux Optimized**: Native desktop integration

## Installation

### Method 1: User Installation (Recommended)
```bash
./scripts/install.sh
```

### Method 2: System Package (Fedora)
```bash
# Build RPM package
rpmbuild -ba media-downloader.spec

# Install package
sudo dnf install media-downloader-1.0.0-1.fc39.noarch.rpm
```

### Method 3: Flatpak
```bash
# Build Flatpak
flatpak-builder build-dir com.example.MediaDownloader.json

# Install locally
flatpak-builder --install build-dir com.example.MediaDownloader.json
```

## Usage

### GUI Mode
```bash
media-downloader-gui
```

### CLI Mode
```bash
media-downloader-cli
```

## Development

### Setup Development Environment
```bash
python3 -m venv venv
source venv/bin/activate
pip install -e .
```

### Building
```bash
python3 setup.py bdist_wheel
```

## License

GPL-3.0-or-later
EOF

# Create build script
cat > scripts/build.sh << 'EOF'
#!/bin/bash
# Build script for Media Downloader

set -e

echo "Building Media Downloader..."

# Clean previous builds
rm -rf build/ dist/ *.egg-info/

# Build wheel
python3 setup.py bdist_wheel

# Build source distribution
python3 setup.py sdist

echo "Build complete! Files are in dist/"
ls -la dist/
EOF

chmod +x scripts/build.sh

echo "✅ Application package structure created!"
echo ""
echo "📁 Directory structure:"
find . -type f | sort

echo ""
echo "🚀 Next steps:"
echo "1. Run: cd media-downloader-app"
echo "2. Create icons in data/icons/ (PNG and SVG formats)"
echo "3. Test install: ./scripts/install.sh"
echo "4. For Fedora package: rpmbuild -ba media-downloader.spec"
echo "5. For Flatpak: flatpak-builder build-dir com.example.MediaDownloader.json"
echo "6. Submit to Flathub: https://github.com/flathub/flathub"
EOF

chmod +x create_app_structure.sh