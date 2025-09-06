import 'dart:async';

import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as THREE;

String gamename = 'Stack Tower';

const leftEx = -0.9;
const rightEx = 0.9;
const frontEx = 0.9;
const backEx = -0.9;
const heighti = 0.08;
var  colorArr = [0x88f404,0xf49604,0xf40404,0xf4de04,0xf404de,0x37f404,0x0f04f4];

var points = 0;
var maxpoints = 0;
var tower;
var currentBlock;
var blockDepth;
var blockWidth;
var dir;
var colorIndex;
var changeColor;
var isGameOver=false;
var matii;

class Block extends THREE.Mesh {
  var width;
  var depth;
  var direction;
  var color;
  var mainX;
  var mainY;
  var mainZ;

  Block(width, height, depth, color, direction, mainX, mainY, mainZ): super(
      THREE.BoxGeometry(width, height, depth),
      THREE.MeshStandardMaterial({THREE.MaterialProperty.emissive:color })
  ) {

    this.width = width;
    this.depth = depth;
    this.direction = direction;
    this.color = color;

    this.mainX = mainX;
    this.mainY = mainY;
    this.mainZ = mainZ;

    var xPos = mainX;
    var yPos = mainY + heighti;
    var  zPos = mainZ;
    if (dir == 1) xPos = leftEx;
    else if (dir == 2) xPos = rightEx;
    else if (dir == 3) zPos = backEx;
    this.extra['yPosOrig']= yPos;
    this.position.setValues(xPos, yPos+heighti, zPos);
  }
}

class StackTowerPage extends StatefulWidget {
  
  const StackTowerPage({super.key});

  @override
  createState() => _State();
}

class _State extends State<StackTowerPage> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late THREE.ThreeJS threeJs;

  var base;

  bool loaded = false;
  var starttext='Start';
  static double defaultspeed=0.015*1.5;

  var speed=defaultspeed;//0.015*3;

  var msg="";

  var rng = new Random();

  var iTime=0.0;
  var mati;

  var wobble=false;


  @override
  void initState() {
    timer = Timer.periodic(const Duration(seconds: 1), (t){
      setState(() {
        data.removeAt(0);
        data.add(threeJs.clock.fps);
        print('fps'+threeJs.clock.fps.toString());
      });
    });
    threeJs = THREE.ThreeJS(
      onSetupComplete: (){
        setState(() {
         // print("setup complete");
        //  loaded=true;
        });
        },
      setup: initPage,
    );
    super.initState();
    iTime=rng.nextDouble()*1000;
    getMaxPoints();
  }

  getMaxPoints() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    //  await prefs.setInt("maxpoints", 0);
    if (prefs.containsKey('maxpoints')) {
      setState(() {
        maxpoints = prefs.getInt('maxpoints')!;
      });
    }


  }

  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    //controls.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: /*loaded?*/Stack(
        children: [

          threeJs.build(),
          loaded?
          Container(
              alignment: Alignment.topCenter,

              child:Container(
                // set the height property to take the screen width
                  width: 350,//MediaQuery.of(context).size.width,
                  height:150,
                  //  Container(
                  //      width:200,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),

                  //    child:
                  child:Column(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,

                      children:[
                        SizedBox(height:10),
                        msg!=''?   Text(msg):SizedBox.shrink(),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:[
                              Text('Score: ', style:TextStyle(color:Colors.lightGreenAccent)),//,backgroundColor: Colors.blue.withOpacity(0.5))),
                              Text(points.toString(), style:TextStyle(fontWeight:FontWeight.bold,color:Colors.white)//.lightGreenAccent)
                              )]),
                        maxpoints>0?Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:[
                              Text("Highest Score: ", style:TextStyle(color:Colors.lightBlueAccent)),
                              Text(maxpoints.toString(),style:TextStyle(/*fontWeight:FontWeight.bold,*/color:Colors.amberAccent))
                            ]):SizedBox.shrink(),
                        isGameOver?Text('Game Over',style:TextStyle(color:Colors.red)):SizedBox.shrink(),
                        SizedBox(height:10),
                        currentBlock == base||isGameOver?
                        ElevatedButton(
                          child: Text(starttext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            if (currentBlock == base || isGameOver) {
                              startGame();
                            }
                          },
                        ):SizedBox.shrink(),

                      ]))):SizedBox.shrink()
       //   Statistics(data: data)
        ],
      )

    );
  }


  newBlock() {
    var b = new Block(
        blockWidth,
        heighti,
        blockDepth,
        colorArr[colorIndex],
        dir,
        currentBlock.position.x,
        currentBlock.extra['yPosOrig'],

        currentBlock.position.z
    );

    b.material?.metalness = 1;
    b.material?.roughness = 0.5;
    threeJs.scene.add(b);
    currentBlock = b;
    ++dir;
    if (dir == 4)
      dir = 1;
    colorIndex += changeColor;
    if (colorIndex == 6) {
      changeColor = -1;
    } else if (colorIndex == 0)
      changeColor = 1;
  }

  checkOverlap() async {
    var blockDir = currentBlock.direction;
    currentBlock.direction = 0;
    var xDiff = (currentBlock.position.x - currentBlock.mainX).abs();
    var zDiff = (currentBlock.position.z - currentBlock.mainZ).abs();
    if (blockDir <= 2) {
      if (xDiff > currentBlock.width) {
        tower.add(currentBlock);
        setState(() {
          isGameOver = true;
        });
      } else {
        var fallWidth = xDiff;
        var overWidth = currentBlock.width - xDiff;
        var fallCen = 0.0;
        var overCen = 0.0;
        var leftPoint = currentBlock.position.x - currentBlock.width / 2;
        if (currentBlock.position.x > currentBlock.mainX) {
          overCen = leftPoint + overWidth / 2;
          fallCen = leftPoint + overWidth + fallWidth / 2;
        } else {
          fallCen = leftPoint + fallWidth / 2;
          overCen = leftPoint + fallWidth + overWidth / 2;
        }
        freeFall(
            fallWidth,
            currentBlock.depth,
            currentBlock.color,
            fallCen,
            currentBlock.position.y,
            currentBlock.position.z
        );
        cutOffBlock(
            overWidth,
            currentBlock.depth,
            currentBlock.color,
            overCen,
            currentBlock.position.y,
            currentBlock.position.z
        );
      }
    } else {
      if (zDiff > currentBlock.depth) {
        setState(() {
          isGameOver = true;
        });

        tower.add(currentBlock);
      } else {
        var fallDepth = zDiff;
        var overDepth = currentBlock.depth - zDiff;
        var fallCen;
        var overCen;
        var backPoint = currentBlock.position.z - currentBlock.depth / 2;
        if (currentBlock.position.z > currentBlock.mainZ) {
          overCen = backPoint + overDepth / 2;
          fallCen = backPoint + overDepth + fallDepth / 2;
        } else {
          fallCen = backPoint + fallDepth / 2;
          overCen = backPoint + fallDepth + overDepth / 2;
        }
        freeFall(
            currentBlock.width,
            fallDepth,
            currentBlock.color,
            currentBlock.position.x,
            currentBlock.position.y,
            fallCen
        );
        cutOffBlock(
            currentBlock.width,
            overDepth,
            currentBlock.color,
            currentBlock.position.x,
            currentBlock.position.y,
            overCen
        );
      }
    }
    if (!isGameOver) {
      // document.getElementById("points").innerHTML = points;
      setState(() {
        ++points;

      });
      if (points % 5 == 0) {
        for (var b in tower) {
          b.position.setY(b.position.y - 0.4);
          b.extra['yPosOrig']-=0.4;//(b.position.y - 0.4);
        }

      }
      newBlock();
      //var speed=0.015;
      // Dont go too fast when tower is high but still increase it as you get higher
      speed+=0.35*defaultspeed/tower.length;

      wobble=true;
      Future.delayed(const Duration(milliseconds: 200), () {
        wobble=false;
      });

    } else {
      setState(() {
        starttext='Restart';

      });
      if (points>maxpoints) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('maxpoints',points);

        setState(() {
          maxpoints=points;
          msg="Congratulations. You got the highest score";
        });
      }

    }
  }

  cutOffBlock(w, d, color, x, y, z) {
    var overLappingArea = new THREE.Mesh(
        new THREE.BoxGeometry(w, heighti, d),
        new THREE.MeshStandardMaterial({THREE.MaterialProperty.emissive:color })//color })
      // new THREE.MeshStandardMaterial({'color': color })
    );
    overLappingArea.material?.metalness = 1;
    overLappingArea.material?.roughness = 0.5;
    overLappingArea.position.setValues(x, y, z);
    tower.add(overLappingArea);
    blockWidth = w;
    blockDepth = d;
    threeJs.scene.remove(currentBlock);
    overLappingArea.extra['yPosOrig']=currentBlock.extra['yPosOrig'];
    currentBlock = overLappingArea;
    threeJs.scene.add(currentBlock);
  }

  var  fallingArea;
  freeFall(w, d, color, x, y, z) {
    fallingArea = new THREE.Mesh(
        new THREE.BoxGeometry(w, heighti, d),
        new THREE.MeshStandardMaterial({ THREE.MaterialProperty.emissive:color })
//        new THREE.MeshStandardMaterial({ 'color':color })
    );
    fallingArea.material.metalness = 1.0;
    fallingArea.material.roughness = 0.5;

    fallingArea.position.setValues(x, y, z);
    threeJs.scene.add(fallingArea);

    Timer(Duration(milliseconds: 400), () {
      threeJs.scene.remove(fallingArea);
      //fallingArea = None;
    });

  }


  startGame() async {
    print("start game");

    if (currentBlock != base) {
      tower.add(currentBlock);

      ++points;
    }
    if (tower.length > 1) {
      //   ++points;

      var wait= await removeTower(tower.length - 1);
      // Wait for the tower to be dismantled
      await Future.delayed(Duration(milliseconds: wait));
      wait=  await centerBase();
      // Wait for the camera to center
      await Future.delayed(Duration(milliseconds: wait));
    }
    setState(() {
      isGameOver = false;
      points = 0;
      msg="";
    });

    blockDepth = 0.8;
    blockWidth = 0.8;
    dir = 1;
    colorIndex = 0;
    changeColor = 1;
    base.position.setValues(0.0, -0.5, 0.0);
    base.extra['yPosOrig']=-0.5;
    currentBlock = base;
    speed=defaultspeed;
    newBlock();

  }

  // Dismantle dower
  removeTower(index) async {
    var delay=70;
    await Timer(Duration(milliseconds: delay), () async {
      threeJs.scene.remove(tower[index]);
      tower.removeLast();
      // setState(() {
      //   --points;

      //});
      if (tower.length > 1) {
        await removeTower(tower.length - 1);

      }
      // document.getElementById("points").innerHTML = points;
      // resolve();

    });


    return delay*(index+2);
  }

  // Move the base back up to -0.5
  centerBase() async {
    var delay=50;
    Timer(Duration(milliseconds: delay), () {
      base.position.setY(base.position.y + 0.1);
      if (base.position.y < -0.5)
        centerBase();
      // document.getElementById("points").innerHTML = points;
      // resolve();*/

    });
    return  (delay*(-base.position.y /*- 0.5*/)/0.1).toInt();
    /*while (base.position.y < -0.5) {
    await upward();
    }*/
  }



  Future<void> initPage() async {
    threeJs.camera = THREE.PerspectiveCamera(50, threeJs.width / threeJs.height, 0.1, 100);

    threeJs.camera.position.setValues(-0.4, 1.0, 1.5);

    threeJs.scene = THREE.Scene();
    threeJs.scene.background = THREE.Color.fromHex32(0xA1D6CB);
   // threeJs.scene.fog = THREE.Fog(0xa0a0a0, 10, 22);
    var light = THREE.DirectionalLight(0x666666, 1.9);
    light.position.setValues(-1, 7, 1);
    threeJs.scene.add(light);

    var geometry = new THREE.PlaneGeometry( 16,16 );

    mati = THREE.ShaderMaterial.fromMap( {
      "uniforms": {
        'iTime': { 'value': 0.0 },
        'iResolution': {'value': new THREE.Vector2(600.0,600.0) }//width/2,height/2) }
//        'iResolution': {'value': new THREE.Vector2(600.0,600.0) }//width/2,height/2) }
      },
      "vertexShader": [
        'void main() {',
        'gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);',
        '}',

      ].join('\n'),
      "fragmentShader": [
        "uniform float iTime;",
        "uniform vec2 iResolution;",

        "const float speed = 0.15;",

        "float hash1( float n ) { return fract(sin(n)*43758.5453); }",
        "vec2  hash2( vec2  p ) { p = vec2( dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)) ); return fract(sin(p)*43758.5453); }",

// The parameter w controls the smoothness
        "vec4 voronoi(in vec2 x, float w) {",
        " vec2 n = floor( x );",
        " vec2 f = fract( x );",

        " vec4 m = vec4( 8.0, 0.0, 0.0, 0.0 );",
        " for( int j=-2; j<=2; j++ )",
        " for( int i=-2; i<=2; i++ )",
        " {",
        "  vec2 g = vec2( float(i),float(j) );",
        "  vec2 o = hash2( n + g );",

        // animate
        "  o = 0.5 + 0.5*sin( iTime * speed + 6.2831*o );",

        // distance to cell
        "  float d = length(g - f + o);",

        // cell color
        "  vec3 col = 0.5 + 0.5*sin( hash1(dot(n+g,vec2(7.0,113.0)))*2.5 + 3.5 + vec3(2.0,3.0,0.0));",
        // in linear space
        "  col = col*col;",

        // do the smooth min for colors and distances
        "  float h = smoothstep( -1.0, 1.0, (m.x-d)/w );",
        "  m.x   = mix( m.x,     d, h ) - h*(1.0-h)*w/(1.0+3.0*w); ",// distance
        "  m.yzw = mix( m.yzw, col, h ) - h*(1.0-h)*w/(1.0+3.0*w);", // color
        " }",

        " return m;",
        "}",

        // https://iquilezles.org/articles/palettes/
        // cosine based palette, 4 vec3 params
        "vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ) {",
        "return a + b*cos( 6.283185*(c*t+d) );",
        "}",

        "void main() {",
        //"void main(out vec4 FragColor, in vec2 FragCoord) {",


        // "void main() {",
        //"vec2 uv = -1.0 + 2.0 * gl_FragCoord.xy / iResolution.xy;",
        //"uv.x *= iResolution.x / iResolution.y;",

        "vec2 p =gl_FragCoord.xy/iResolution.y;",
        "p += hash2( p ) * 0.005;",

        "vec4 v = voronoi( 1.5 * p, 0.05 );",

        "vec3 col = palette((v.x + v.y + v.z + v.w) * 0.3 - (p.y - 0.5) * 0.3,",
        "vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,0.5),vec3(0.8,0.90,0.30)",
        ");",

        "col *= 0.9;",
        "col += 0.1;",

        "col = pow(col, vec3(0.5));",

        "gl_FragColor = vec4(col.x, col.y, col.z, 1.0);",//0.0, 1.0, 0.0, 1.0);", //gl_FragColor.rgb = col;",
        // "FragColor = vec4( col, 1.0 );",
        "}"


      ].join('\n')

    });

    var  plane = new THREE.Mesh( geometry,mati);
    plane.position.setValues(0.0, -8.0, -2.0);
    threeJs.scene.add( plane );

    var geo =  THREE.BoxGeometry(0.8, 0.08, 0.8);

    var mat = THREE.MeshPhysicalMaterial();


    mat.emissive=THREE.Color(0x049ef4);
    // mat.color=THREE.Color(0x049ef4);
    mat.metalness = 1;
    mat.roughness = 0.5;


    base = new THREE.Mesh(geo, mat);
    base.position.setValues(0.0, -0.5, 0.0);
    threeJs.scene.add(base);

    tower = [base];
    currentBlock  = base;

    threeJs.camera.lookAt(base.position);

    threeJs.domElement.addEventListener(THREE.PeripheralType.keydown, (event){
      if (event.keyId==32&& !isGameOver && currentBlock != base)
        checkOverlap();
    });

    threeJs.domElement.addEventListener(THREE.PeripheralType.pointerdown, (event){
      if ( !isGameOver && currentBlock != base)
        checkOverlap();

    });

    setState(() {
      loaded = true;
    });

    threeJs.addAnimationEvent((frameTime){
      animate(frameTime);
    });
    startGame();
    setState(() {
      msg="Press Space to lower the block";
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      setState(() {
        msg="";
      });
    });


  }

  animate(frameTime) async {
    if (!loaded) {
      return;
    }
    if (currentBlock is Block) {
      if (currentBlock.direction == 1) {
        if (currentBlock.position.x + speed > rightEx)
          currentBlock.direction = 2;
        else
          currentBlock.position.setX(currentBlock.position.x + speed);
      } else if (currentBlock.direction == 2) {
        if (currentBlock.position.x - speed < leftEx)
          currentBlock.direction = 1;
        else
          currentBlock.position.setX(currentBlock.position.x - speed);
      } else if (currentBlock.direction == 3) {
        if (currentBlock.position.z + speed > frontEx)
          currentBlock.direction = 4;
        else
          currentBlock.position.setZ(currentBlock.position.z + speed);
      } else if (currentBlock.direction == 4) {
        if (currentBlock.position.z - speed < backEx)
          currentBlock.direction = 3;
        else
          currentBlock.position.setZ(currentBlock.position.z - speed);
      }
      if (fallingArea != null) {
        fallingArea.position.setY(fallingArea.position.y - 0.08);
      }
    }


    // Move the shader
    iTime+=40.0*speed*frameTime;//0.05;
    if (wobble) {
      tower[tower.length-1].rotateX(0.006 * (cos(10 * iTime)));
      tower[tower.length-1].rotateY(0.006 * (sin(10 * iTime)));
      tower[tower.length-1].rotateZ(0.006 * (sin(10 * iTime)));
      if (tower[tower.length-1].position.y>tower[tower.length-1].extra['yPosOrig']) {
        tower[tower.length - 1].position.setY(
            tower[tower.length - 1].position.y - frameTime);
        print("down");
      }

    }

    mati.uniforms[ 'iTime' ] = { 'value': iTime };

  }


}
