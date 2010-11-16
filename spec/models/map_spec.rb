require 'spec_helper'

describe Map do
  
  it 'should give the lat of the top of a map correctly for an example value at zoom level 17' do 
    Map.top(51.5010403096676, 17, MAP_HEIGHT).should be_close(51.5031860768795, 0.0000000001)
  end 
  
  it 'should give the lat of the bottom of a map correctly for an example value at zoom level 17' do 
    Map.bottom(51.5010403096676, 17, MAP_HEIGHT).should be_close(51.4988945424557, 0.0000000001)
  end
  
  it 'should give the long of the left edge of a map correctly for an example value at zoom level 17' do 
    Map.left(-0.0914398192630478, 17, MAP_WIDTH).should be_close(-0.0935855836777082, 0.0000000001)
  end
  
  it 'should give the long of the right edge of a map correctly for an example value at zoom level 17' do 
    Map.right(-0.0914398192630478, 17, MAP_WIDTH).should be_close(-0.0892940547201092, 0.0000000001)
  end
  
  it 'should give the correct zoom level for some example coords' do
    Map.zoom_to_coords(51.5057200938463,51.5010403096676, -0.0914398192630478, -0.0888722778623277, MAP_WIDTH).should == 16
  end
  
  it 'should give the max visible zoom level if the real zoom level for the coords is higher than the max visible level' do
    Map.zoom_to_coords(51.50104, 51.50098, -0.09144, -0.09028, MAP_WIDTH).should == MAX_VISIBLE_ZOOM
  end
  
  
end
