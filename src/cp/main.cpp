#include <iostream>

#include "../../liburing/src/include/liburing.h"
#include "ioring/ioring_manager.hpp"

using namespace ioring;

int main()
{
    IORingManager manager;
    manager = IORingManager();
    manager.submit_read_request();

    std::cout << "Hello, World!" << std::endl;
    return 0;
}