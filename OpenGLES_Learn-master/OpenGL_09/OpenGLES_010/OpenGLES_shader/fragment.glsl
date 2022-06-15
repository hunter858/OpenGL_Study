varying lowp vec4 DestinationColor; // 1

void main(void) { // 2
    gl_FragColor = DestinationColor; // 3
}

//1 这是从vertex shader中传入的变量，这里和vertex shader定义的一致。而额外加了一个关键字：lowp。在fragment shader中，必须给出一个计算的精度。出于性能考虑，总使用最低精度是一个好习惯。这里就是设置成最低的精度。如果你需要，也可以设置成medp或者highp.
//2 也是从main开始嘛
//3 正如你在vertex shader中必须设置gl_Position, 在fragment shader中必须设置gl_FragColor.