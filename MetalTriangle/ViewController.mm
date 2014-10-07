//
//  ViewController.m
//  MetalTriangle
//
//  Created by Hernan Saez on 9/21/14.
//  Copyright (c) 2014 Hernan Saez. All rights reserved.
//

#import "ViewController.h"

using namespace crimild;
using namespace crimild::metal;

@interface ViewController ()

@end

@implementation ViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) loadScene
{
    Pointer<Group> scene(new Group());

    float vertices[] = {
        -1.0f, -1.0f, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f,
        1.0f, -1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 1.0f,
        0.0f, 1.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f
    };
    
    unsigned short indices[] = {
        0, 1, 2
    };
    
    int triangleCount = 0;
    for ( float x = -15.0f; x <= 15.0f; x += 5.0f ) {
        for ( float y = -15.0f; y <= 15.0f; y += 5.0f ) {
            for ( float z = -15.0f; z <= 0.0f; z += 5.0f ) {
                Pointer<Primitive> primitive(new Primitive(Primitive::Type::TRIANGLES));
                primitive->setVertexBuffer(new VertexBufferObject(VertexFormat::VF_P3_C4, 3, vertices));
                primitive->setIndexBuffer(new IndexBufferObject(3, indices));

                Pointer<Geometry> geometry( new Geometry("triangle") );
                geometry->attachPrimitive( primitive.get() );
                
                geometry->local().setTranslate( x, y, z );
                geometry->local().rotate().fromAxisAngle( Vector3f( 0.0f, 1.0f, 0.0f ), Numericf::TWO_PI * ( std::rand() % 100 ) / 100.0f );
                
                geometry->attachComponent( new LambdaComponent( []( Node *node, const Time &t ) {
                    node->local().rotate() *= Quaternion4f::createFromAxisAngle( Vector3f( 0.0f, 1.0f, 0.0f ), t.getDeltaTime() );
                    node->perform( UpdateWorldState() );
                }));
                
                scene->attachNode( geometry.get() );
                ++triangleCount;
            }
        }
    }
    
    Pointer<Camera> camera(new Camera());
    camera->setFrustum( Frustumf( 45.0f, self.view.bounds.size.width / self.view.bounds.size.height, 0.1f, 100.0f ) );
    camera->setRenderPass( new MetalRenderPass() );
    camera->local().setTranslate( 0.0f, 0.0f, 40.0f );
    
    scene->attachNode( camera.get() );

    self.simulation->setScene(scene.get());
}

@end

