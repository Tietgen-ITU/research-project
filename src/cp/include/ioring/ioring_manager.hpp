namespace ioring
{

    /*
     * Class to handle and manage the Submission and Completion queues (SQ and CQ) of an io_uring.
     * This also means that it will handle sending requests to the rings and receiving the completions
     */
    class IORingManager
    {
    public:
        IORingManager();
        ~IORingManager();
        void submit_read_request();
        void submit_write_request();
    };
}