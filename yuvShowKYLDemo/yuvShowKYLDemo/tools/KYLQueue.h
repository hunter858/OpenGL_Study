//
//  KYLQueue.h
//  yuvShowKYLDemo
//
//  Created by yulu kong on 2019/7/31.
//  Copyright © 2019 yulu kong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef enum {
    KYLCustomWorkQueue,
    KYLCustomFreeQueue
} KYLCustomQueueType;

typedef struct KYLCustomQueueNode {
    void    *data;//结点中使用void *类型的data存放我们需要的sampleBuffer,使用index记录当前装入结点的sampleBuffer的索引，
                  //以便我们在取出结点时比较是否是按照顺序取出，结点中还装着同类型下一个结点的元素。
    size_t  size;  // data size 数据大小
    long    index;
    struct  KYLCustomQueueNode *next; //记录下一个节点指针
} KYLCustomQueueNode;

//队列中即为我们装载的结点数量，因为我们采用的是预先分配固定内存，
//所以工作队列与空闲队列的和始终不变(因为结点中的元素不在工作队列就在空闲队列)
typedef struct KYLCustomQueue {
    int size;
    KYLCustomQueueType type; //队列类型
    KYLCustomQueueNode *front; //队列头
    KYLCustomQueueNode *rear;  //队列尾
} KYLCustomQueue;

class KYLQueue
{
public:
    KYLCustomQueue *m_free_queue;//空闲队列
    KYLCustomQueue *m_work_queue;//工作队列
    
    KYLQueue();
    ~KYLQueue();
    
    // Queue Operation

    
    /**
     初始化队列

     @param queue 队列指针 KYLCustomQueue
     @param type 队列类型 KYLCustomQueueType
     */
    void InitQueue(KYLCustomQueue *queue,
                   KYLCustomQueueType type);

    
    /**
     入队

     @param queue 队列指针 KYLCustomQueue
     @param node 队列类型 KYLCustomQueueType
     */
    void EnQueue(KYLCustomQueue *queue,
                 KYLCustomQueueNode *node);

    
    /**
     出队

     @param queue 队列指针 KYLCustomQueue
     @return 出队的节点指针 KYLCustomQueueNode
     */
    KYLCustomQueueNode *DeQueue(KYLCustomQueue *queue);

    
    /**
     清空队列

     @param queue 队列指针KYLCustomQueue
     */
    void ClearKYLCustomQueue(KYLCustomQueue *queue);
    
    
    /**
     释放节点

     @param node 节点指针KYLCustomQueueNode
     */
    void FreeNode(KYLCustomQueueNode* node);
    
    
    /**
     重置队列，释放工作队列和空闲队列资源

     @param workQueue 工作队列指针 KYLCustomQueue
     @param freeQueue 空闲队列指针 KYLCustomQueue
     */
    void ResetFreeQueue(KYLCustomQueue *workQueue, KYLCustomQueue *freeQueue);
    
private:

    pthread_mutex_t free_queue_mutex; //互斥锁
    pthread_mutex_t work_queue_mutex;
};


NS_ASSUME_NONNULL_END
