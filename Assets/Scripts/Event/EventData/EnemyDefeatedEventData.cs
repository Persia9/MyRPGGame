using System;
using ObjectPool;

namespace Event.EventData
{
    public class EnemyDefeatedEventData : EventArgs, IResettable
    {
        public string EnemyName { get; set; }
        public int ExperienceGained { get; set; }

        public void Reset()
        {
            EnemyName = null;
            ExperienceGained = 0;
        }
    }
}