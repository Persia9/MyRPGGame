using UnityEngine;
using System;
using Event.EventData;

namespace Event.Example
{
    public class Player : MonoBehaviour
    {
        private string playerName = "Player1";

        private void OnEnable()
        {
            EventManager.Subscribe<EnemyDefeatedEventData>(OnEnemyDefeated);
            EventManager.Subscribe<ItemCollectedEventData>(OnItemCollected);
        }

        private void OnDisable()
        {
            EventManager.Unsubscribe<EnemyDefeatedEventData>(OnEnemyDefeated);
            EventManager.Unsubscribe<ItemCollectedEventData>(OnItemCollected);
        }

        private void OnEnemyDefeated(object sender, EnemyDefeatedEventData eventData)
        {
            Debug.Log($"{playerName} 获得了 {eventData.ExperienceGained} 点经验，击败了 {eventData.EnemyName}！");
        }

        private void OnItemCollected(object sender, ItemCollectedEventData eventData)
        {
            Debug.Log($"{playerName} 收集了 {eventData.Quantity} 个 {eventData.ItemName}！");
        }
    }
}