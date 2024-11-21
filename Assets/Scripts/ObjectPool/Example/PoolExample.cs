using System.Threading.Tasks;
using UnityEngine;

namespace ObjectPool.Example
{
    public class PoolExample : MonoBehaviour
    {
        void Start()
        {
            var pool = ObjectPoolManager.Instance.GetPool<PooledObject>();

            Parallel.For(0, 100, i =>
            {
                var obj = pool.Get();
                obj.Data = i;

                Debug.Log($"使用对象，Data = {obj.Data}");

                pool.Release(obj);
            });
        }

        private void OnDestroy()
        {
            // 应用程序退出时，清理所有对象池
            ObjectPoolManager.Instance.DisposeAll();
        }
    }
}