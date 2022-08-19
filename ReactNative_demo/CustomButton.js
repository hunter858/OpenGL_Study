import React, {Component } from 'react';
import ConnectTools from '../Native/NativeIOSModule';

import {
    Text,
    View,
    StyleSheet,
    TouchableHighlight,
    
    } from 'react-native';

export default class TestButton extends Component {

    constructor(props){
        super(props);

    }

    // static propTypes = {
    //     titleName: React.PropTypes.string.isRequired,
    // }


    // getDefaultProps(){
    //     // 全局调用一次，不能 setState
    //     console.log("getDefaultProps");
    // }
    
    // getInitialState(){
    //     //全局调用一次，不能 setState
    //     console.log("getInitialState");
    // }

    componentWillMount(){
        //全局调用一次，能setState
        console.log("componentWillMount");
    }
    
    componentDidMount(){
        //全局调用一次，能setState
        console.log("componentDidMount");
    }
    
    componentWillReceiveProps(){
         //全局调用次数 >=1，能setState
        console.log("componentWillReceiveProps");
    }

    componentWillUpdate(){
         //全局调用次数 >=0，不能 setState
        console.log("componentWillUpdate");
    }

    componentDidUpdate(){
         //全局调用次数 >=0，不能 setState
        console.log("componentDidUpdate");
    }

    componentWillUnmount(){
         //全局调用次数 >=0，不能 setState
        console.log("componentWillUnmount");
    }

    render(){
        //全局调用次数 >=1，不能 setState
        return(
            <View>
                <TouchableHighlight  onPress={()=>this.onPress()}>
                <Text style={{color: 'red',fontSize:34,fontWeight:'bold'}}>{this.props.titleName}</Text>
                </TouchableHighlight></View> 
        );
    }

    async onPress() {
        // let value = {'title':'pengchao'};

        // func1 (异步方法 无回调)
        ConnectTools.openView(value);


        // 常量

        // func2 （Promise 方法 只能请求到成功的结果）
        let result = await ConnectTools.request2(value);
        if (result){
            //success
            alert(JSON.stringify(result));
        }

        
        // func2 
        // ConnectTools.request2(value).then((result)=>{
            // console.log('success'+ JSON.stringify(result));
            // alert('success' + JSON.stringify(result) );
        // },(code,message,error)=>{
            // console.log(code + message + error);
            // alert( code + "----"+ message + "----"+ error );
            //coder \ message\ error ,只收到了 code == 'failed'
        // });

       


        ///func3 同步方法
        // alert(JSON.stringify(value));
        // let value2 = ConnectTools.testSyncFunc('value4');   
        // console.log(JSON.stringify(value2));
        
        
        //func4 
        // ConnectTools.request("deviceName", function(error,result1,result2){
        //     console.log(error);
        //     console.log(result1);
        //     console.log(result2);
        // });

       console.log(ConnectTools.constDict()); 
       

        

    }
}
const styles = StyleSheet.create({
    helloWorld:{
        color:'red',//颜色红色
        fontSize:34,//
        fontWeight:'bold'//粗体
    }
})