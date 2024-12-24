using System;
using System.Collections.Concurrent;

namespace Event
{
    public static class EventManager
    {
        private static readonly ConcurrentDictionary<Type, Delegate>
            events = new ConcurrentDictionary<Type, Delegate>();

        public static void Subscribe<T>(EventHandler<T> listener) where T : EventArgs
        {
            events.AddOrUpdate(typeof(T), listener,
                (type, existingDelegate) => { return Delegate.Combine(existingDelegate, listener); });
        }

        public static void Unsubscribe<T>(EventHandler<T> listener) where T : EventArgs
        {
            if (events.TryGetValue(typeof(T), out var existingDelegate))
            {
                var newDelegate = Delegate.Remove(existingDelegate, listener);
                if (newDelegate == null)
                {
                    events.TryRemove(typeof(T), out _);
                }
                else
                {
                    events[typeof(T)] = newDelegate;
                }
            }
        }

        public static void Trigger<T>(object sender, T eventData) where T : EventArgs
        {
            if (events.TryGetValue(typeof(T), out var existingDelegate))
            {
                var callback = existingDelegate as EventHandler<T>;
                callback?.Invoke(sender, eventData);
            }
        }
    }
}