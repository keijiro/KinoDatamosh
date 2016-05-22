//
// Kino/Datamosh - Video compression artifact effect
//
// Copyright (C) 2016 Keijiro Takahashi
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
using UnityEngine;

namespace Kino
{
    [RequireComponent(typeof(Camera))]
    public class Datamosh : MonoBehaviour
    {
        #region Public properties and methods

        /// Size of compression block.
        public int blockSize {
            get { return Mathf.Max(4, _blockSize) ; }
            set { _blockSize = value; }
        }

        [SerializeField] int _blockSize = 16;

        /// Start glitching.
        public void Glitch()
        {
            _sequence = 1;
        }

        /// Force to end glitching.
        public void Reset()
        {
            _sequence = 0;
        }

        #endregion

        #region Private properties

        [SerializeField] Shader _shader;

        Material _material;

        RenderTexture _workBuffer;
        RenderTexture _dispBuffer;
        int _sequence;

        RenderTexture GetTemporaryDispBuffer(RenderTexture source)
        {
            return RenderTexture.GetTemporary(
                source.width / _blockSize,
                source.height / _blockSize,
                0, RenderTextureFormat.ARGBHalf
            );
        }


        #endregion

        #region MonoBehaviour functions

        void OnEnable()
        {
            var shader = Shader.Find("Hidden/Kino/Datamosh");
            _material = new Material(shader);
            _material.hideFlags = HideFlags.DontSave;

            GetComponent<Camera>().depthTextureMode |=
                DepthTextureMode.Depth | DepthTextureMode.MotionVectors;

            _sequence = 0;
        }

        void OnDisable()
        {
            if (_workBuffer != null)
            {
                RenderTexture.ReleaseTemporary(_workBuffer);
                _workBuffer = null;
            }

            if (_dispBuffer != null)
            {
                RenderTexture.ReleaseTemporary(_dispBuffer);
                _dispBuffer = null;
            }

            DestroyImmediate(_material);
            _material = null;
        }

        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {
            _material.SetFloat("_BlockSize", _blockSize);

            if (_sequence == 0)
            {
                // Update the working buffer with the current frame.
                if (_workBuffer != null) RenderTexture.ReleaseTemporary(_workBuffer);
                _workBuffer = RenderTexture.GetTemporary(source.width, source.height);
                Graphics.Blit(source, _workBuffer);

                // Blit without effect.
                Graphics.Blit(source, destination);
            }
            else if (_sequence == 1)
            {
                // Initialize the displacement buffer.
                if (_dispBuffer != null) RenderTexture.ReleaseTemporary(_dispBuffer);
                _dispBuffer = GetTemporaryDispBuffer(source);
                Graphics.Blit(null, _dispBuffer, _material, 0);

                // Simply blit the working buffer because motion vectors
                // might be not ready (because of camera switching).
                Graphics.Blit(_workBuffer, destination);

                // Automatically advance to the next step.
                _sequence++;
            }
            else
            {
                // Update the displaceent buffer.
                var disp = GetTemporaryDispBuffer(source);
                Graphics.Blit(_dispBuffer, disp, _material, 1);
                RenderTexture.ReleaseTemporary(_dispBuffer);
                _dispBuffer = disp;

                // Moshing
                var temp = RenderTexture.GetTemporary(source.width, source.height);
                _material.SetTexture("_WorkTex", _workBuffer);
                _material.SetTexture("_DispTex", _dispBuffer);
                _workBuffer.filterMode = FilterMode.Point;
                _dispBuffer.filterMode = FilterMode.Point;
                Graphics.Blit(source, temp, _material, 2);

                // Update the state and release temporary objects.
                RenderTexture.ReleaseTemporary(_workBuffer);
                _workBuffer = temp;

                // Blit the result.
                Graphics.Blit(_workBuffer, destination);
            }
        }

        #endregion
    }
}
