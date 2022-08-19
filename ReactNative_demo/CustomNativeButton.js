import React, { Component } from 'react';
import {
    Text,
    View,
    StyleSheet,
    TouchableHighlight,
    requireNativeComponent
    } from 'react-native';

var CustomButtonView  = requireNativeComponent('CustomButtonView');

// requireNativeComponent('shareBt', ZKShareBt);
// type Props = {};
export default class CustomNativeButton extends Component {
  render() {
    return (
      <CustomButtonView {...this.props}></CustomButtonView>
    );
  }
}
