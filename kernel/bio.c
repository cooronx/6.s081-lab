// Buffer cache.
//
// The buffer cache is a linked list of buf structures holding
// cached copies of disk block contents.  Caching disk blocks
// in memory reduces the number of disk reads and also provides
// a synchronization point for disk blocks used by multiple processes.
//
// Interface:
// * To get a buffer for a particular disk block, call bread.
// * After changing buffer data, call bwrite to write it to disk.
// * When done with the buffer, call brelse.
// * Do not use the buffer after calling brelse.
// * Only one process at a time can use a buffer,
//     so do not keep them longer than necessary.


#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "buf.h"

#define NBUCKETS 13

struct {
  struct spinlock lock[NBUCKETS];
  struct buf buf[NBUF];

  // Linked list of all buffers, through prev/next.
  // Sorted by how recently the buffer was used.
  // head.next is most recent, head.prev is least.
  struct buf head[NBUCKETS];
} bcache;

int
hash(int no){
  return no % NBUCKETS;
}


void
binit(void)
{
  struct buf *b;

  for(int i = 0;i<NBUCKETS;++i){
    initlock(&bcache.lock[i], "bcache");
    bcache.head[i].prev = &bcache.head[i];
    bcache.head[i].next = &bcache.head[i];
  }

  // Create linked list of buffers
  int i = 0;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++,i++){
    i = i % NBUCKETS;
    b->next = bcache.head[i].next;
    b->prev = &bcache.head[i];
    initsleeplock(&b->lock, "buffer");
    bcache.head[i].next->prev = b;
    bcache.head[i].next = b;
  }
}

// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
  struct buf *b;

  int hashkey = hash(blockno);
  acquire(&bcache.lock[hashkey]);

  // Is the block already cached?
  for(b = bcache.head[hashkey].next; b != &bcache.head[hashkey]; b = b->next){
    if(b->dev == dev && b->blockno == blockno){
      b->refcnt++;
      release(&bcache.lock[hashkey]);
      acquiresleep(&b->lock);
      return b;
    }
  }

  // Not cached.
  // Recycle the least recently used (LRU) unused buffer.
  for(b = bcache.head[hashkey].prev; b != &bcache.head[hashkey]; b = b->prev){
    if(b->refcnt == 0) {
      b->dev = dev;
      b->blockno = blockno;
      b->valid = 0;
      b->refcnt = 1;
      release(&bcache.lock[hashkey]);
      acquiresleep(&b->lock);
      return b;
    }
  }

  //如果自己的这个链上没有空的了
  //去别人的地方偷取
  //偷取之前先要把自己的锁给释放了，不然会造成死锁
  release(&bcache.lock[hashkey]);

  //找其他桶里面的,只找一圈。
  //其实我在想是不是如果没有找到可以喊它一直找
  for(int i = hashkey + 1;i != hashkey;++i){
    i = i % NBUCKETS;
    acquire(&bcache.lock[i]);
    for(b = bcache.head[i].prev;b != &bcache.head[i];b = b->prev){
      if(b->refcnt == 0){
        b->dev = dev;
        b->blockno = blockno;
        b->valid = 0;
        b->refcnt = 1;
        //从对应的链表中删除
        b->next->prev = b->prev;
        b->prev->next = b->next;
        //挂载到当前链表上面
        b->next = bcache.head[hashkey].next;
        b->prev = &bcache.head[hashkey];
        bcache.head[hashkey].next->prev = b;
        bcache.head[hashkey].next = b;
        release(&bcache.lock[i]);
        acquiresleep(&b->lock);
        return b;
      }
    }
    release(&bcache.lock[i]);
  }


  panic("bget: no buffers");
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("bwrite");
  virtio_disk_rw(b, 1);
}

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("brelse");

  

  releasesleep(&b->lock);
  int hashkey = hash(b->blockno);

  acquire(&bcache.lock[hashkey]);
  b->refcnt--;
  if (b->refcnt == 0) {
    // no one is waiting for it.
    b->next->prev = b->prev;
    b->prev->next = b->next;
    b->next = bcache.head[hashkey].next;
    b->prev = &bcache.head[hashkey];
    bcache.head[hashkey].next->prev = b;
    bcache.head[hashkey].next = b;
  }
  
  release(&bcache.lock[hashkey]);
}

void
bpin(struct buf *b) {
  int hashkey = hash(b->blockno);
  acquire(&bcache.lock[hashkey]);
  b->refcnt++;
  release(&bcache.lock[hashkey]);
}

void
bunpin(struct buf *b) {
  int hashkey = hash(b->blockno);
  acquire(&bcache.lock[hashkey]);
  b->refcnt--;
  release(&bcache.lock[hashkey]);
}


