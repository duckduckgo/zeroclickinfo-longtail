"""
Copyright (c) 2010, Dhruv Matani

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"""


class LyricWriter(object):
    """
    Writes the lyrics to a file
    """
    def __init__(self, handle):
        """
        handle can either be a string (file path) or an
        open file handle to which the writer will write to
        """
        if isinstance(handle, type("")):
            self.fh = open(handle)
        else:
            self.fh = handle

    def write_lyric(self, title, artist, album, url, lyric_text):
        """
        Format of the lyric_data: ((song title, artist), lyric text)
        """
        print (title, artist, album, url, lyric_text)
