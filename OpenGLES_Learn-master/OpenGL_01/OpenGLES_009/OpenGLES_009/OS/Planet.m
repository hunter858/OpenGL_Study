/*

===== IMPORTANT =====

=====================

File: Planet.m	: taken from the Touchfighter example
Abstract: Planet.

Version: 2.0


*/

#import "Planet.h"

GLshort	*_texData=NULL;

@implementation Planet

- (id) init:(GLint)stacks slices:(GLint)slices radius:(GLfloat)radius squash:(GLfloat) squash
{
    unsigned int colorIncrment=0;				
	unsigned int blue=0;
	unsigned int red=255;
	int numVertices=0;
	
	m_Scale=radius;						
	m_Squash=squash;
	
	colorIncrment=255/stacks;					
	
	if ((self = [super init])) 
	{
		m_Stacks = stacks;
		m_Slices = slices;
		m_VertexData = nil;
		
		// Vertices
		
		GLfloat *vPtr = m_VertexData = 			
        (GLfloat*)malloc(sizeof(GLfloat) * 3 * ((m_Slices*2+2) * (m_Stacks)));		
		
		// Color data
		
		GLubyte *cPtr = m_ColorData = 					
        (GLubyte*)malloc(sizeof(GLubyte) * 4 * ((m_Slices*2+2) * (m_Stacks)));				
		
		// Normal pointers for lighting
		
		GLfloat *nPtr = m_NormalData = 				//1
        (GLfloat*)malloc(sizeof(GLfloat) * 3 * ((m_Slices*2+2) * (m_Stacks)));			
		unsigned int phiIdx, thetaIdx;
		
		// Latitude
		
		for(phiIdx=0; phiIdx < m_Stacks; phiIdx++)			
		{
			// Starts at -1.57 goes up to +1.57 radians
			
			// The first circle
            
			float phi0 = M_PI * ((float)(phiIdx+0) * (1.0/(float)(m_Stacks)) - 0.5);	
			
			// The next, or second one.
            
			float phi1 = M_PI * ((float)(phiIdx+1) * (1.0/(float)(m_Stacks)) - 0.5);				
			float cosPhi0 = cos(phi0);				
			float sinPhi0 = sin(phi0);
			float cosPhi1 = cos(phi1);
			float sinPhi1 = sin(phi1);
			
			float cosTheta, sinTheta;
			
			// Longitude
			
			for(thetaIdx=0; thetaIdx < m_Slices; thetaIdx++)			
			{
				// Increment along the longitude circle each "slice"
				
				float theta = 2.0*M_PI * ((float)thetaIdx) * (1.0/(float)(m_Slices-1));			
				cosTheta = cos(theta);		
				sinTheta = sin(theta);
				
				// We're generating a vertical pair of points, such 
				// as the first point of stack 0 and the first point of stack 1
				// above it. This is how TRIANGLE_STRIPS work, 
				// taking a set of 4 vertices and essentially drawing two triangles
				// at a time. The first is v0-v1-v2 and the next is v2-v1-v3, etc.
				
				
				// Get x-y-z for the first vertex of stack.
				
				vPtr[0] = m_Scale*cosPhi0 * cosTheta; 
				vPtr[1] = m_Scale*sinPhi0*m_Squash;			
				vPtr[2] = m_Scale*cosPhi0 * sinTheta; 
				
				// The same but for the vertex immediately above the previous one
				
				vPtr[3] = m_Scale*cosPhi1 * cosTheta; 
				vPtr[4] = m_Scale*sinPhi1*m_Squash;		
				vPtr[5] = m_Scale* cosPhi1 * sinTheta; 
                
				// Normal pointers for lighting
				
				nPtr[0] = cosPhi0 * cosTheta; 	//2
				nPtr[1] = sinPhi0;		
                nPtr[2] = cosPhi0 * sinTheta;
                
				nPtr[3] = cosPhi1 * cosTheta; 	//3
                nPtr[4] = sinPhi1;	
                nPtr[5] = cosPhi1 * sinTheta; 
                
				cPtr[0] = red;				
				cPtr[1] = 0;
				cPtr[2] = blue;
				cPtr[4] = red;
				cPtr[5] = 0;
				cPtr[6] = blue;
				cPtr[3] = cPtr[7] = 255;
				
				cPtr += 2*4;				
				vPtr += 2*3;
				nPtr +=2*3;                                                  //4
                
			}
			
			blue+=colorIncrment;				
			red-=colorIncrment;
		}
		
		numVertices=(vPtr-m_VertexData)/6;
	}
	
	return self;
}

/****************************************************************************************
 * execute : strips out any stuff that I don't need from execute, used for testing		*
 *		the moon. Rotation is in radians.												*
 ****************************************************************************************/
- (bool)execute
{		
	glMatrixMode(GL_MODELVIEW);				
	glEnable(GL_CULL_FACE);					
	glCullFace(GL_BACK);					
	
	glEnableClientState(GL_NORMAL_ARRAY);			//1
	glEnableClientState(GL_VERTEX_ARRAY);			
	glEnableClientState(GL_COLOR_ARRAY);			
	
	glVertexPointer(3, GL_FLOAT, 0, m_VertexData);			
	glNormalPointer(GL_FLOAT, 0, m_NormalData);			//2
    
	glColorPointer(4, GL_UNSIGNED_BYTE, 0, m_ColorData);		
	glDrawArrays(GL_TRIANGLE_STRIP, 0, (m_Slices+1)*2*(m_Stacks-1)+2);	
	
	return true;
}

-(void)getPositionX:(GLfloat *)x Y:(GLfloat *)y Z:(GLfloat *)z
{
	*x=m_Pos[0];
	*y=m_Pos[1];
	*z=m_Pos[2];
}

-(void)setPositionX:(GLfloat)x Y:(GLfloat)y Z:(GLfloat)z
{
	m_Pos[0]=x;
	m_Pos[1]=y;
	m_Pos[2]=z;	
}

-(GLfloat)getRotation
{
	return m_Angle;
}

-(void)setRotation:(GLfloat)angle
{
	m_Angle=angle;
}

-(void)incrementRotation
{
	m_Angle+=m_RotationalIncrement;
}

-(GLfloat)getRotationalIncrement
{
	return m_RotationalIncrement;
}

-(void)setRotationalIncrement:(GLfloat)inc
{
	m_RotationalIncrement=inc;
}
@end