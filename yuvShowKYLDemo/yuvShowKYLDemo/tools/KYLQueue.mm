//
//  KYLQueue.m
//  yuvShowKYLDemo
//
//  Created by yulu kong on 2019/7/31.
//  Copyright © 2019 yulu kong. All rights reserved.
//

/*******************************************************************************************************************
 
 我们将空闲队列设计为头进头出，影响不大，因为我们每次只需要从空闲队列中取出一个空结点以供我们装入相机数据，所以没必要按照尾进头出的方式保证结点的顺序。
 我们将工作队列设计为尾进头出，因为我们要确保从相机中捕获的数据是连续的，以便后期我们播放出来的画面也是连续的，所以工作队列必须保证尾进头出。
 这样做我们相当于实现了用空闲队列当做缓冲队列，在正常情况
 (fps=30,即每秒产生30帧数据，大约每33ms产生一帧数据)，如果在33ms内对数据进行的操作可以正常完成，则工作队列会保持始终为0或1，
 但是如果长期工作或遇到某一帧数据处理较慢的情况(即处理时间大于33ms)则工作队列的长度会增加，
 而正因为我们使用了这样的队列会保护那一帧处理慢的数据在仍然能够正常处理完。
 这种情景仅用于短时间内仅有几帧数据处理较慢，如果比如1s内有20几帧数据都处理很慢则可能导致工作队列太长，则体现不出此队列的优势。
 ********************************************************************************************************************/


#import "KYLQueue.h"
#import <pthread.h>
#include "log4cplus.h"

#pragma mark - Queue Size   设置队列的长度，不可过长
const int KYLCustomQueueSize = 3;

const static char *kModuleName = "KYLQueueProcess";

#pragma mark - Init

//构造函数
KYLQueue::KYLQueue(){
    m_free_queue = (KYLCustomQueue *)malloc(sizeof(struct KYLCustomQueue));
    m_work_queue = (KYLCustomQueue *)malloc(sizeof(struct KYLCustomQueue));
    
    InitQueue(m_free_queue, KYLCustomFreeQueue);
    InitQueue(m_work_queue, KYLCustomWorkQueue);
    
    for (int i = 0; i < KYLCustomQueueSize; i++) {
        KYLCustomQueueNode *node = (KYLCustomQueueNode *)malloc(sizeof(struct KYLCustomQueueNode));
        node->data = NULL;
        node->size = 0;
        node->index= 0;
        this->EnQueue(m_free_queue, node);
    }
    
    pthread_mutex_init(&free_queue_mutex, NULL);
    pthread_mutex_init(&work_queue_mutex, NULL);
    
    log4cplus_info(kModuleName, "%s: Init finish !",__func__);
}

/**
 初始化队列
 
 @param queue 队列指针 KYLCustomQueue
 @param type 队列类型 KYLCustomQueueType
 */

void KYLQueue::InitQueue(KYLCustomQueue *queue, KYLCustomQueueType type) {
    if (queue != NULL) {
        queue->type  = type;
        queue->size  = 0;
        queue->front = 0;
        queue->rear  = 0;
    }
}

#pragma mark - Main Operation

/**
 入队
 
 @param queue 队列指针 KYLCustomQueue
 @param node 队列类型 KYLCustomQueueType
 */
void KYLQueue::EnQueue(KYLCustomQueue *queue, KYLCustomQueueNode *node) {
    if (queue == NULL) {
        log4cplus_debug(kModuleName, "%s: current queue is NULL",__func__);
        return;
    }
    
    if (node==NULL) {
        log4cplus_debug(kModuleName, "%s: current node is NULL",__func__);
        return;
    }
    
    node->next = NULL;
    
    if (KYLCustomFreeQueue == queue->type) {
        pthread_mutex_lock(&free_queue_mutex);
        
        if (queue->front == NULL) {
            queue->front = node;
            queue->rear  = node;
        }else {
            /*
             // tail in,head out
             freeQueue->rear->next = node;
             freeQueue->rear = node;
             */
            
            // head in,head out
            node->next = queue->front;
            queue->front = node;
        }
        queue->size += 1;
        log4cplus_debug(kModuleName, "%s: free queue size=%d",__func__,queue->size);
        pthread_mutex_unlock(&free_queue_mutex);
    }
    
    if (KYLCustomWorkQueue == queue->type) {
        pthread_mutex_lock(&work_queue_mutex);
        //TODO
        static long nodeIndex = 0;
        node->index=(++nodeIndex);
        if (queue->front == NULL) {
            queue->front = node;
            queue->rear  = node;
        }else {
            queue->rear->next   = node;
            queue->rear         = node;
        }
        queue->size += 1;
        log4cplus_debug(kModuleName, "%s: work queue size=%d",__func__,queue->size);
        pthread_mutex_unlock(&work_queue_mutex);
    }
}

/**
 出队
 
 @param queue 队列指针 KYLCustomQueue
 @return 出队的节点指针 KYLCustomQueueNode
 */
KYLCustomQueueNode* KYLQueue::DeQueue(KYLCustomQueue *queue) {
    if (queue == NULL) {
        log4cplus_debug(kModuleName, "%s: current queue is NULL",__func__);
        return NULL;
    }
    
    const char *type = queue->type == KYLCustomWorkQueue ? "work queue" : "free queue";
    pthread_mutex_t *queue_mutex = ((queue->type == KYLCustomWorkQueue) ? &work_queue_mutex : &free_queue_mutex);
    KYLCustomQueueNode *element = NULL;
    
    pthread_mutex_lock(queue_mutex);
    element = queue->front;
    if(element == NULL) {
        pthread_mutex_unlock(queue_mutex);
        log4cplus_debug(kModuleName, "%s: The node is NULL",__func__);
        return NULL;
    }
    
    queue->front = queue->front->next;
    queue->size -= 1;
    pthread_mutex_unlock(queue_mutex);
    
    log4cplus_debug(kModuleName, "%s: type=%s size=%d",__func__,type,queue->size);
    return element;
}

/**
 重置队列，释放工作队列和空闲队列资源
 
 @param workQueue 工作队列指针 KYLCustomQueue
 @param freeQueue 空闲队列指针 KYLCustomQueue
 */
void KYLQueue::ResetFreeQueue(KYLCustomQueue *workQueue, KYLCustomQueue *freeQueue) {
    if (workQueue == NULL) {
        log4cplus_debug(kModuleName, "%s: The WorkQueue is NULL",__func__);
        return;
    }
    
    if (freeQueue == NULL) {
        log4cplus_debug(kModuleName, "%s: The FreeQueue is NULL",__func__);
        return;
    }
    
    int workQueueSize = workQueue->size;
    if (workQueueSize > 0) {
        for (int i = 0; i < workQueueSize; i++) {
            KYLCustomQueueNode *node = DeQueue(workQueue);
            CFRelease(node->data);
            node->data = NULL;
            EnQueue(freeQueue, node);
        }
    }
    log4cplus_info(kModuleName, "%s: ResetFreeQueue : The work queue size is %d, free queue size is %d",__func__,workQueue->size, freeQueue->size);
}

/**
 清空队列
 
 @param queue 队列指针KYLCustomQueue
 */
void KYLQueue::ClearKYLCustomQueue(KYLCustomQueue *queue) {
    while (queue->size) {
        KYLCustomQueueNode *node = this->DeQueue(queue);
        this->FreeNode(node);
    }
    
    log4cplus_info(kModuleName, "%s: Clear KYLQueue queue",__func__);
}

/**
 释放节点
 
 @param node 节点指针KYLCustomQueueNode
 */
void KYLQueue::FreeNode(KYLCustomQueueNode* node) {
    if(node != NULL){
        free(node->data);
        free(node);
    }
}
