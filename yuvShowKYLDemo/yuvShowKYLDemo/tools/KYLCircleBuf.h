//
//  KYLCircleBuf.h
//  yuvShowKYLDemo
//
//  Created by yulu kong on 2019/7/27.
//  Copyright © 2019 yulu kong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct tag_AV_VIDEO_BUF_HEAD
{
    unsigned int head; /* Õ∑£¨±ÿ–Îµ»”⁄0xFF00FF */
    unsigned int timestamp; // ±º‰¥¡£¨»Áπ˚ «¬ºœÒ£¨‘ÚÃÓ¬ºœÒµƒ ±º‰¥¡£¨»Áπ˚ « µ ± ”∆µ£¨‘ÚŒ™0
    unsigned int len;    /*≥§∂»*/
    unsigned int frametype;
}AV_VIDEO_BUF_HEAD;

typedef struct tag_stAVStreamHead
{
    unsigned int nCodecID;     // refer to SEP2P_ENUM_AV_CODECID
    char   nParameter;     // Video: refer to SEP2P_ENUM_VIDEO_FRAME.   Audio:(samplerate << 2) | (databits << 1) | (channel), samplerate refer to SEP2P_ENUM_AUDIO_SAMPLERATE; databits refer to SEP2P_ENUM_AUDIO_DATABITS; channel refer to SEP2P_ENUM_AUDIO_CHANNEL
    char   nLivePlayback;// Video: 0:live video or audio;  1:playback video or audio
    char   reserve1[2];
    unsigned int  nStreamDataLen;    // Stream data size after following struct 'STREAM_HEAD'
    unsigned int  nTimestamp;        // Timestamp of the frame, in milliseconds
    unsigned char  nNumConnected;    // amount that app connected this device for M,X series when nCodecID is AV_CODECID_VIDEO...
    unsigned char  nNumLiveView;    // amount that app is at liveview UI for M,X series when nCodecID is AV_CODECID_VIDEO...
    char   reserve2[2];
    unsigned int  nPlaybackID;        // reserve2[2,5] -> nPlaybackID, modified on 20141201
}AV_STREAM_HEAD;


class KYLCircleBuf
{
public:
    KYLCircleBuf();
    ~KYLCircleBuf();
    
    bool Create(int size);
    void Release();
    int Read(void* buf, int size);
    int  ReadByPeer(void* buf, int size);
    int Write(void* buf, int size);
    int GetStock();
    void Reset();
    bool IsBufCreateSucceed(){return m_bCreateBufSucceed;}
    char * ReadOneFrame(int &len);
    char* ReadOneFrame1(int &len, AV_VIDEO_BUF_HEAD & videobufhead);
    char* ReadOneFrame2(int &len, AV_STREAM_HEAD & videobufhead);
    
private:
    int Read1(void* buf, int size);
    
    
protected:
    char* m_pBuf;
    int m_nSize;
    int m_nStock;
    int m_nReadPos;
    int m_nWritePos;
    
    int  m_nTimeout;
    
    NSCondition *m_Lock;
    
private:
    
    int m_n;
    bool m_bCreateBufSucceed;
    
};



NS_ASSUME_NONNULL_END
