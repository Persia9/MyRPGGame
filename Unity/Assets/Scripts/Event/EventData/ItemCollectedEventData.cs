using System;
using ObjectPool;

namespace Event.EventData
{
    public class ItemCollectedEventData : EventArgs, IResettable
    {
        public string ItemName { get; set; }
        public int Quantity { get; set; }

        public void Reset()
        {
            ItemName = null;
            Quantity = 0;
        }
    }
}