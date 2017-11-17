using System.Collections.Generic;

namespace PayPalRetailSDK
{
    public class SynchronizedCallbackStore<T>
    {
        private readonly object _lockObj = new object();

        public List<T> Callbacks { get; } = new List<T>();

        public int Add(T callback)
        {
            lock (_lockObj)
            {
                Callbacks.Add(callback);
            }

            return Count;
        }

        public int Remove(T callback)
        {
            lock (_lockObj)
            {
                Callbacks.Remove(callback);
            }

            return Count;
        }

        public int Count
        {
            get
            {
                lock (_lockObj)
                {
                    return Callbacks.Count;
                }
            }
        }

        public void Clear()
        {
            lock (_lockObj)
            {
                Callbacks.Clear();
            }
        }
    }
}
