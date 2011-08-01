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
    Map.zoom_to_coords(-0.0914398192630478, -0.0888722778623277, 51.5057200938463, 51.5010403096676, MAP_HEIGHT, MAP_WIDTH).should == 16
  end
  
  it 'should give the correct zoom level for some example coords very close to each other' do
    Map.zoom_to_coords(-1.55394, -1.55371, 52.51866, 52.51869, MAP_HEIGHT, MAP_WIDTH).should == 16
  end
  
  it 'should give the max visible zoom level if the real zoom level for the coords is higher than the max visible level' do
    Map.zoom_to_coords(-0.09144, -0.09028, 51.50104, 51.50098, MAP_HEIGHT, MAP_WIDTH).should == MAX_VISIBLE_ZOOM
  end
  
  describe 'when asked for other locations' do 

    describe 'when the current zoom level is >= the minimum zoom level for showing other markers' do 
    
      it 'should ask for stops and stop areas in the bounding box without passing any highlight param' do 
        Stop.should_receive(:find_in_bounding_box).with(anything(), 
                                                        anything(),
                                                        anything(), 
                                                        anything()).and_return([])
        StopArea.should_receive(:find_in_bounding_box).with(anything(), 
                                                            anything(), 
                                                            anything(), 
                                                            anything()).and_return([])
        Map.other_locations(51.505720, -0.088872, MIN_ZOOM_FOR_OTHER_MARKERS, MAP_HEIGHT, MAP_WIDTH)
      end
      
    end
    
    describe 'when the current zoom level is < the minimum zoom level for showing other markers' do 
    
      describe 'when no highlight param is passed' do 
        
        it 'should not ask for stops and stop areas in the bounding box' do 
          Stop.should_not_receive(:find_in_bounding_box)
          StopArea.should_not_receive(:find_in_bounding_box)
          Map.other_locations(51.505720, -0.088872, MIN_ZOOM_FOR_OTHER_MARKERS - 1, MAP_HEIGHT, MAP_WIDTH)
        end
      
      end
      
      describe 'when a highlight param is passed' do 
      
        it 'should ask for stops and stop areas in the bounding box' do 
          Stop.should_receive(:find_in_bounding_box).with(anything(), 
                                                          anything(), 
                                                          anything(), 
                                                          anything(),
                                                          :has_content).and_return([])
          StopArea.should_receive(:find_in_bounding_box).with(anything(), 
                                                              anything(), 
                                                              anything(), 
                                                              anything(),
                                                              :has_content).and_return([])
          Map.other_locations(51.505720, -0.088872, MIN_ZOOM_FOR_OTHER_MARKERS - 1, MAP_HEIGHT, MAP_WIDTH, :has_content)
        end
        
      end
    
    end
    
  end
  
end
