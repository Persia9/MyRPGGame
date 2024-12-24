using ObjectPool;
using UnityEngine;

namespace Event.Example
{
    public class GameController : MonoBehaviour
    {
        private void Start()
        {
            // 创建玩家
            GameObject playerObject = new GameObject("Player1");
            playerObject.AddComponent<Player>();


            // 创建敌人并模拟击败
            GameObject enemyObject = new GameObject("Enemy1");
            Enemy enemy = enemyObject.AddComponent<Enemy>();
            enemy.Defeat();

            // 创建物品并模拟收集
            GameObject itemObject = new GameObject("Item1");
            Item item = itemObject.AddComponent<Item>();
            item.Collect();
        }

        private void OnDestroy()
        {
            // 应用程序退出时，清理所有对象池
            ObjectPoolManager.Instance.DisposeAll();
        }
    }
}