using UnityEngine;
using System.Collections;

public class CameraSwitcher : MonoBehaviour
{
    [SerializeField] Transform[] _targetList;
    [SerializeField] float _interval = 3.0f;

    float Interval {
        get { return Mathf.Max(1.0f / 30, _interval); }
    }

    int _targetIndex;

    IEnumerator Start()
    {
        while (true)
        {
            yield return new WaitForSeconds(Interval);
            SwitchCamera();
            KickGlitch();
        }
    }

    void SwitchCamera()
    {
        _targetIndex = (_targetIndex + 1) % _targetList.Length;

        var follow = GetComponent<Klak.Motion.SmoothFollow>();
        follow.target = _targetList[_targetIndex];
        follow.Snap();

        transform.localRotation = Quaternion.Euler(
            Random.Range(-20.0f, 20.0f),
            Random.Range(-180.0f, 180.0f),
            Random.Range(-30.0f, 30.0f)
        );
    }

    void KickGlitch()
    {
        FindObjectOfType<Kino.Datamosh>().Glitch();
    }
}
