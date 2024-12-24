using System;
using System.Collections.Concurrent;

namespace ObjectPool
{
    public class ObjectPoolManager
    {
        private static readonly Lazy<ObjectPoolManager> instance =
            new Lazy<ObjectPoolManager>(() => new ObjectPoolManager());

        public static ObjectPoolManager Instance => instance.Value;

        private readonly ConcurrentDictionary<Type, object> _pools = new ConcurrentDictionary<Type, object>();

        private ObjectPoolManager()
        {
        }

        public ObjectPool<T> GetPool<T>() where T : class, IResettable, new()
        {
            var type = typeof(T);

            if (!_pools.TryGetValue(type, out var pool))
            {
                var newPool = new ObjectPool<T>();
                _pools[type] = newPool;
                return newPool;
            }

            return (ObjectPool<T>)pool;
        }

        public void DisposeAll()
        {
            foreach (var pool in _pools.Values)
            {
                if (pool is IDisposable disposable)
                {
                    disposable.Dispose();
                }
            }

            _pools.Clear();
        }
    }
}