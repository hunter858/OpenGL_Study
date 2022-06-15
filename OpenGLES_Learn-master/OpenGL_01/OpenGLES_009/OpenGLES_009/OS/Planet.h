/****************************************************************************************
 * Planet.h : lifted from the iPhone Touchfighter exmaple code. Thanks! Apple!			*
 ****************************************************************************************/
#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>


@interface Planet : NSObject 
{
	
@private
	GLfloat			*m_VertexData;
	GLubyte			*m_ColorData;
	GLfloat			*m_NormalData;
	GLint			m_Stacks, m_Slices;
	GLfloat			m_Scale;						
	GLfloat			m_Squash;
	GLfloat			m_Angle;
	GLfloat			m_Pos[3];
	GLfloat			m_RotationalIncrement;
}

-(bool)execute;
-(id) init:(GLint)stacks slices:(GLint)slices radius:(GLfloat)radius squash:(GLfloat) squash;
-(void)getPositionX:(GLfloat *)x Y:(GLfloat *)y Z:(GLfloat *)z;
-(void)setPositionX:(GLfloat)x Y:(GLfloat)y Z:(GLfloat)z;
-(GLfloat)getRotation;
-(void)setRotation:(GLfloat)angle;
-(GLfloat)getRotationalIncrement;
-(void)setRotationalIncrement:(GLfloat)inc;
-(void)incrementRotation;

@end
