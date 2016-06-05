Kino/Datamosh
=============

*Datamosh* is a post-processing effect that simulates [video compression
artifacts][Wikipedia], specifically one called [datamoshing][KnowYourMeme].

![Gif][Gif1]
![Gif][Gif2]

*Datamosh* is part of the *Kino* effect suite. See the [GitHub repositories]
[Kino] for other effects included in the suite.

System Requirements
-------------------

- Unity 5.4 or later versions

*Datamosh* requires [motion vectors][MotionVectors] that is newly introduced in
Unity 5.4. Motion vector rendering is only supported on the platforms that has
RGHalf texture format support. This requirement must be met in most of the
desktop/console platforms, but rarely supported in the mobile platforms.

License
-------

Copyright (C) 2016 Keijiro Takahashi

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[Wikipedia]: https://en.wikipedia.org/wiki/Compression_artifact
[KnowYourMeme]: http://knowyourmeme.com/memes/datamoshing
[Gif1]: https://66.media.tumblr.com/6bf2ae7d3af6d38a61f1c57ca86556aa/tumblr_o8azn6iSbB1qio469o1_400.gif
[Gif2]: https://67.media.tumblr.com/60652235832a915be25bb32979c13f09/tumblr_o8azn6iSbB1qio469o2_400.gif
[Kino]: https://github.com/search?q=kino+user%3Akeijiro&type=Repositories
[MotionVectors]: http://docs.unity3d.com/540/Documentation/ScriptReference/DepthTextureMode.MotionVectors.html
