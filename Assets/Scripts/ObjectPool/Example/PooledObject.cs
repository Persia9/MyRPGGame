using System;

namespace ObjectPool.Example
{
    public class PooledObject : IResettable, IDisposable
    {
        public int Data { get; set; }

        public void Reset()
        {
            Data = 0;
        }

        public void Dispose()
        {
            // 释放资源的代码
        }
    }
}