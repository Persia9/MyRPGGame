using Event.EventData;
using ObjectPool;
using UnityEngine;

namespace Event.Example
{
    public class Enemy : MonoBehaviour
    {
        public string enemyName = "Goblin";
        public int experienceReward = 10;

        public void Defeat()
        {
            Debug.Log($"{enemyName} 被击败！");

            var pool = ObjectPoolManager.Instance.GetPool<EnemyDefeatedEventData>();
            var eventData = pool.Get();

            try
            {
                eventData.EnemyName = enemyName;
                eventData.ExperienceGained = experienceReward;

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