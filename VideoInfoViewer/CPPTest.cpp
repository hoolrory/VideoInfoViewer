//
//  CPPTest.cpp
//  VideoInfoViewer
//
//  Created by Hool, Rory on 7/22/16.
//  Copyright © 2016 RoryHool. All rights reserved.
//

#include <iostream>

#include "CPPTest.h"
#include "MP4.Parser.h"
using namespace MP4;

void CPPTest::test(const char* test)
{
    std::cout << "C++ printing test: " << test;
    MP4::Parser * parser;
    
    parser = new MP4::Parser((char*)test);
    
    delete parser;

}