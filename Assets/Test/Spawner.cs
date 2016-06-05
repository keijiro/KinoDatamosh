using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class Spawner : MonoBehaviour
{
    [SerializeField] GameObject _prefab;
    [SerializeField] int _instanceCount = 10;
    [SerializeField] float _interval = 0.5f;
    [SerializeField] float _velocity = 5;
    [SerializeField] Bounds _range = new Bounds(Vector3.zero, Vector3.one);

    IEnumerator Start()
    {
        var queue = new Queue<GameObject>();

        while (true)
        {
            while (queue.Count >= _instanceCount)
                Destroy(queue.Dequeue());

            queue.Enqueue(Spawn());

            yield return new WaitForSeconds(_interval);
        }
    }

    GameObject Spawn()
    {
        var pos = new Vector3(Random.value, Random.value, Random.value);

        pos = Vector3.Scale((pos - Vector3.one * 0.5f), _range.size);
        pos += Vector3.Scale(Vector3.one, _range.center);

        pos = transform.TransformPoint(pos);

        var go = (GameObject)Instantiate(_prefab, pos, Random.rotation);

        var rb = go.GetComponent<Rigidbody>();
        rb.velocity = Random.insideUnitSphere * _velocity;

        return go;
    }

    void OnDrawGizmos()
    {
        Gizmos.color = Color.yellow;
        Gizmos.matrix = transform.localToWorldMatrix;
        Gizmos.DrawWireCube(_range.center, _range.size);
    }
}
