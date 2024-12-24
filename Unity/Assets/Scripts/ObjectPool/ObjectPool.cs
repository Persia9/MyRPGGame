using System;
using System.Collections.Concurrent;
using System.Threading;

namespace ObjectPool
{
    public class ObjectPool<T> : IDisposable where T : class, IResettable, new()
    {
        private readonly ConcurrentBag<PooledObjectWrapper> objects = new ConcurrentBag<PooledObjectWrapper>();
        private readonly Timer cleanUpTimer;
        private readonly TimeSpan objectIdleTimeout;
        private readonly int maxPoolSize;

        public ObjectPool(int size = 100, TimeSpan? timeout = null, TimeSpan? cleanUpInterval = null)
        {
            maxPoolSize = size;
            objectIdleTimeout = timeout ?? TimeSpan.FromMinutes(5);
            cleanUpInterval = cleanUpInterval ?? TimeSpan.FromMinutes(1);

            cleanUpTimer = new Timer(CleanUpIdleObjects, null, cleanUpInterval.Value, cleanUpInterval.Value);
        }

        public T Get()
        {
            if (objects.TryTake(out var wrapper))
            {
                if (DateTime.UtcNow - wrapper.LastAccessed <= objectIdleTimeout)
                {
                    wrapper.LastAccessed = DateTime.UtcNow;
                    return wrapper.Instance;
                }
                else
                {
                    if (wrapper.Instance is IDisposable disposable)
                    {
                        disposable.Dispose();
                    }
                }
            }

            return new T();
        }

        public void Release(T item)
        {
            if (objects.Count >= maxPoolSize)
            {
                if (item is IDisposable disposable)
                {
                    disposable.Dispose();
                }

                return;
            }

            item.Reset();

            var wrapper = new PooledObjectWrapper
            {
                Instance = item,
                LastAccessed = DateTime.UtcNow
            };

            objects.Add(wrapper);
        }

        private void CleanUpIdleObjects(object state)
        {
            var cutoff = DateTime.UtcNow - objectIdleTimeout;
            var itemsToKeep = new ConcurrentBag<PooledObjectWrapper>();

            while (objects.TryTake(out var wrapper))
            {
                if (wrapper.LastAccessed >= cutoff)
                {
                    itemsToKeep.Add(wrapper);
                }
                else
                {
                    if (wrapper.Instance is IDisposable disposable)
                    {
                        disposable.Dispose();
                    }
                }
            }

            foreach (var item in itemsToKeep)
            {
                objects.Add(item);
            }
        }

        public void Dispose()
        {
            cleanUpTimer.Dispose();

            while (objects.TryTake(out var wrapper))
            {
                if (wrapper.Instance is IDisposable disposable)
                {
                    disposable.Dispose();
                }
            }
        }

        private class PooledObjectWrapper
        {
            public T Instance { get; set; }
            public DateTime LastAccessed { get; set; }
        }
    }
}