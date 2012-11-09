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


import sqlite3

class LyricWriter(object):
    """
    Writes the lyrics to a SQLITE3 database file
    """
    def __init__(self, file_path):
        self.conn = sqlite3.connect(file_path)
        c = self.conn.cursor()
        self.ctr = 0
        self.commit_interval = 10

        c.execute("""CREATE TABLE IF NOT EXISTS LYRICS(title VARCHAR(300) NOT NULL,
            artist VARCHAR(200) NOT NULL,
            album VARCHAR(200) NOT NULL,
            url VARCHAR(2000) NOT NULL,
            lyric_text TEXT NOT NULL)""")

    def write_lyric(self, title, artist, album, url, lyric_text):
        """
        Format of the lyric_data: ((song title, artist), lyric text)
        """
        c = self.conn.cursor()
        data = (title, artist, album, url, lyric_text)
        c.execute("""INSERT INTO LYRICS(title, artist, album, url, lyric_text) VALUES(?, ?, ?, ?, ?)""", data)
        self.ctr += 1
        if (self.ctr % self.commit_interval) == 0:
            self.conn.commit()

    def __del__(self):
        self.conn.commit()
