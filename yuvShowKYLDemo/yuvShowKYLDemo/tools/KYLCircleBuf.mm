//
//  KYLCircleBuf.m
//  yuvShowKYLDemo
//
//  Created by yulu kong on 2019/7/27.
//  Copyright © 2019 yulu kong. All rights reserved.
//

#import "KYLCircleBuf.h"

KYLCircleBuf::KYLCircleBuf()
{
    m_pBuf = NULL;
    m_nSize = 0;
    m_nStock= 0;
    m_nWritePos= 0;
    m_nReadPos = 0;
    m_bCreateBufSucceed = false;
    m_Lock = [[NSCondition alloc] init];
}

KYLCircleBuf::~KYLCircleBuf()
{
    Release();
    
    //[m_Lock release];
    m_Lock = nil;
}

bool KYLCircleBuf::Create(int size)
{
    if (size <= 0)
    {
        m_bCreateBufSucceed = false;
        return false;
    }
    if (m_pBuf != NULL)
    {
        delete[] m_pBuf;
        m_pBuf = NULL;
    }
    m_pBuf = new char[size];
    if(m_pBuf == NULL)
    {
        m_bCreateBufSucceed = false;
        return false;
    }
    m_nSize = size;
    m_nStock = 0;
    m_nWritePos = 0;
    m_nReadPos = 0;
    m_bCreateBufSucceed = true;
    return true;
}

void KYLCircleBuf::Release()
{
    [m_Lock lock];
    
    m_bCreateBufSucceed = false;
    if (m_pBuf == NULL)
    {
        [m_Lock unlock];
        return;
    }
    if(m_pBuf != NULL)
    {
        delete[] m_pBuf;
        m_pBuf = NULL;
    }
    m_nSize = 0;
    m_nStock = 0;
    m_nReadPos = 0;
    m_nWritePos = 0;
    [m_Lock unlock];
}

char* KYLCircleBuf::ReadOneFrame1(int &len, AV_VIDEO_BUF_HEAD & videobufhead)
{
    [m_Lock lock];
    len = 0;
    if(m_nStock == 0)
    {
        [m_Lock unlock];
        return NULL;
    }
    char *pbuf = NULL;
    AV_VIDEO_BUF_HEAD videohead;
    int nRet = Read1((char*)&videohead, sizeof(AV_VIDEO_BUF_HEAD));
    if(nRet == 0)
    {
        [m_Lock unlock];
        return NULL;
    }
    pbuf = new char[videohead.len] ;
    nRet = Read1((char*)pbuf, videohead.len);
    if(nRet == 0)
    {
        delete []pbuf;
        pbuf = NULL;
        [m_Lock unlock];
        return NULL;
    }
    memcpy((char*)&videobufhead, (char*)&videohead, sizeof(AV_VIDEO_BUF_HEAD));
    len = videohead.len;
    [m_Lock unlock];
    return pbuf;
}

char* KYLCircleBuf::ReadOneFrame2(int &len, AV_STREAM_HEAD & streambufhead)
{
    [m_Lock lock];
    len = 0;
    if(m_nStock == 0)
    {
        [m_Lock unlock];
        return NULL;
    }
    char *pbuf = NULL;
    AV_STREAM_HEAD streamhead;
    int nRet = Read1((char*)&streamhead, sizeof(AV_STREAM_HEAD));
    if(nRet == 0)
    {
        [m_Lock unlock];
        return NULL;
    }
    pbuf = new char[streamhead.nStreamDataLen] ;
    nRet = Read1((char*)pbuf, streamhead.nStreamDataLen);
    if(nRet == 0)
    {
        delete []pbuf;
        pbuf = NULL;
        [m_Lock unlock];
        return NULL;
    }
    memcpy((char*)&streambufhead, (char*)&streamhead, sizeof(AV_STREAM_HEAD));
    len = streamhead.nStreamDataLen;
    [m_Lock unlock];
    return pbuf;
    
}

char* KYLCircleBuf::ReadOneFrame(int &len)
{
    [m_Lock lock];
    len = 0;
    if(m_nStock == 0)
    {
        [m_Lock unlock];
        return NULL;
    }
    char *pbuf = NULL;
    AV_VIDEO_BUF_HEAD videohead;
    int nRet = Read1((char*)&videohead, sizeof(AV_VIDEO_BUF_HEAD));
    if(nRet == 0)
    {
        [m_Lock unlock];
        return NULL;
    }
    pbuf = new char[videohead.len] ;
    if(pbuf == NULL)
    {
        [m_Lock unlock];
        return NULL;
    }
    nRet = Read1((char*)pbuf, videohead.len);
    if(nRet == 0)
    {
        delete []pbuf;
        pbuf = NULL;
        [m_Lock unlock];
        return NULL;
    }
    len = videohead.len;
    [m_Lock unlock];
    return pbuf;
    
}

int KYLCircleBuf::Read1(void* buf, int size)
{
    if (m_nStock < size)
    {
        return 0;
    }
    int left = 0;
    int offs = m_nWritePos - m_nReadPos;
    if (offs > 0)
    {
        memcpy(buf, &m_pBuf[m_nReadPos], size);
        m_nReadPos += size;
    }
    else
    {
        offs = m_nSize - m_nReadPos;
        if (offs > size)
        {
            memcpy(buf, &m_pBuf[m_nReadPos], size);
            m_nReadPos += size;
        }
        else
        {
            memcpy(buf, &m_pBuf[m_nReadPos], offs);
            left = size - offs;
            memcpy(&((char*)buf)[offs], m_pBuf, left);
            m_nReadPos = left;
        }
    }
    m_nStock -= size;
    return size;
}


//从缓存中读数据，当缓存数据不够读则读取失败，返回为0
int KYLCircleBuf::Read(void* buf, int size)
{
    //Lock the buffer
    [m_Lock lock];
    if (m_nStock < size)
    {
        [m_Lock unlock];
        return 0;
    }
    int left = 0;
    int offs = m_nWritePos - m_nReadPos;
    if (offs > 0)
    {
        memcpy(buf, &m_pBuf[m_nReadPos], size);
        m_nReadPos += size;
    }
    else
    {
        offs = m_nSize - m_nReadPos;
        if (offs > size)
        {
            memcpy(buf, &m_pBuf[m_nReadPos], size);
            m_nReadPos += size;
        }
        else
        {
            memcpy(buf, &m_pBuf[m_nReadPos], offs);
            left = size - offs;
            memcpy(&((char*)buf)[offs], m_pBuf, left);
            m_nReadPos = left;
        }
    }
    m_nStock -= size;
    [m_Lock unlock];
    return size;
}

int  KYLCircleBuf::ReadByPeer(void* buf, int size)
{
    //Lock the buffer
    [m_Lock lock];
    if(m_nStock < size)
    {
        [m_Lock unlock];
        return 0;
    }
    int left = 0;
    int offs = m_nWritePos - m_nReadPos;
    if(offs > 0)
    {
        memcpy(buf, &m_pBuf[m_nReadPos], size);
    }else{
        offs = m_nSize - m_nReadPos;
        if(offs > size)
        {
            memcpy(buf, &m_pBuf[m_nReadPos], size);
        }else{
            memcpy(buf, &m_pBuf[m_nReadPos], offs);
            left = size - offs;
            memcpy(&((char*)buf)[offs], m_pBuf, left);
            //m_nReadPos = left;
        }
    }
    [m_Lock unlock];
    return size;
}


int KYLCircleBuf::Write(void* buf, int size)
{
    //Lock the buffer
    [m_Lock lock];
    // the buffer is full
    if (m_nStock + size > m_nSize)
    {
        [m_Lock unlock];
        return 0;
    }
    int left = 0;
    int offs = m_nSize - m_nWritePos;
    if (offs > size)
    {
        memcpy(&m_pBuf[m_nWritePos], buf, size);
        m_nWritePos += size;
    }
    else
    {
        memcpy(&m_pBuf[m_nWritePos], buf, offs);
        left = size - offs;
        memcpy(m_pBuf, &((char*)buf)[offs], left);
        m_nWritePos = left;
    }
    
    m_nStock += size;
    [m_Lock unlock];
    return size;
    
}

int KYLCircleBuf::GetStock()
{
    int n;
    [m_Lock lock];
    n =  m_nStock;
    [m_Lock unlock];
    
    return n;
}

void KYLCircleBuf::Reset()
{
    [m_Lock lock];
    m_nReadPos = 0;
    m_nWritePos = 0;
    m_nStock = 0;
    [m_Lock unlock];
}
