using Event.EventData;
using ObjectPool;
using UnityEngine;

namespace Event.Example
{
    public class Item : MonoBehaviour
    {
        public string itemName = "Health Potion";
        public int quantity = 1;

        public void Collect()
        {
            Debug.Log($"{itemName} 被收集！");

            var pool = ObjectPoolManager.Instance.GetPool<ItemCollectedEventData>();
            var eventData = pool.Get();

            try
            {
                eventData.ItemName = itemName;
                eventData.Quantity = quantity;

                EventManager.Trigger(this, eventData);
            }
            finally
            {
                pool.Release(eventData);
            }

            Destroy(gameObject);
        }
    }
}