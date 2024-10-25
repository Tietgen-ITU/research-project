#include <linux/io_uring.h>

#define CQE_SUCCESSFUL(cqe) (cqe->res < 0)
#define CQE_IS_IO_ERROR(cqe) (cqe->res == -EIO)

/*
    Defines the data that is passed back
    in the completion queue after an operation from the submission queue is completed.

    This is an exact copy of the io_uring_cqe structure from the Linux kernel.
 */
struct completion_queue_event
{
    /*
        Data passed back at completion time.
        This is used to identify the submission queue entry(sqe) that was completed.

        https://kernel.dk/io_uring.pdf provides the idea to specify this field to the pointer of the sqe
    */
    __u64 user_data;

    /*
        Result code for the event.
        If this is a postive value then it is a success, otherwise if it is negative then it is an error.

        The positive value is the number of bytes that were read or written.

        To check that it is an IO error use the CQE_IS_IO_ERROR macro.
    */
    __s32 result;

    /*
        Flags for the completion queue entry.
        This is used to specify additional information about the completion queue entry.

        This is not used according to https://kernel.dk/io_uring.pdf
    */
    __u32 flags;
};

/*
    Defines the data that is passed to the submission queue to request an operation.
*/
struct submission_queue_entry
{
    /*
        Operation code for the submission queue entry.
        This is used to specify the type of operation that is requested.

        In particular, use the defined codes in the io_uring.h header file.

        For example, an IO request to write or read would be IORING_OP_READV or IORING_OP_WRITEV.
    */
    __u8 operation_code;

    /*
        TODO: Describe what it does
     */
    __u8 flags;

    /*
        The priority of this request. This is normally set by syscalls like ioprio_set(2).

        In the liburing library, this is not being used, for that reason it is 0 at initalization
        unless something else has changed it.
     */
    __u16 ioprio;

    // File descriptor of the operation to perform on
    __s32 file_descriptor;

    union
    {
        // Offset into the file in which the operation should be performed on
        __u64 offset;
        __u64 addr2;
    };

    union
    {
        /*
            Is the address at which the operation should perform the IO. This only required if the operation
            code describes an operation taht transfers data.

            An example is if the operation is vecorized, like readv or writev, then this would be a pointer to
            the iovec array.
        */
        __u64 addr; /* pointer to buffer or iovecs */
        __u64 splice_off_in;
    };

    /*
        The length of the buffer or the number of iovecs in the addr field.
    */
    __u32 len;

    // NOTE: Not really explained
    union
    {

        __kernel_rwf_t rw_flags;
        __u32 fsync_flags;
        __u16 poll_events;   /* compatibility */
        __u32 poll32_events; /* word-reversed for BE */
        __u32 sync_range_flags;
        __u32 msg_flags;
        __u32 timeout_flags;
        __u32 accept_flags;
        __u32 cancel_flags;
        __u32 open_flags;
        __u32 statx_flags;
        __u32 fadvise_advice;
        __u32 splice_flags;
    };

    __u64 user_data; /* data to be passed back at completion time */

    union
    {
        struct
        {
            /* pack this to avoid bogus arm OABI complaints */
            union
            {
                /* index into fixed buffers, if used */
                __u16 buf_index;
                /* for grouped buffer selection */
                __u16 buf_group;
            } __attribute__((packed));
            /* personality to use, if used */
            __u16 personality;
            __s32 splice_fd_in;
        };
        __u64 __pad2[3];
    };
};